const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Must match the channel created in MainActivity.kt
const CHANNEL_ID = "ga_laundry_updates";

// Keep these in sync with OrderStatus in lib/models/order_model.dart
// (the frontend UI also uses "In Process" and "Ready to Claim", so both spellings are accepted)
const READY_STATUSES = ["Ready for Pickup", "Ready to Claim"];
const PROCESSING_STATUSES = ["In Process", "Sorting", "Washing", "Drying"];
const CLAIMED_STATUS = "Claimed";

// The app does not send SMS anymore. Every update is a push notification (FCM).
// The app saves each phone's token in `deviceTokens` (see push_notification_service.dart):
//   deviceTokens/{token} = { token, role: "customer" | "admin", customerId, platform, updatedAt }

async function tokensFor(query) {
  const snap = await query.get();
  return snap.docs.map((d) => d.id);
}

/**
 * Sends one push to many phones and removes tokens that are no longer valid.
 * Returns { sent, failed }.
 */
async function sendPush(tokens, { title, body, data }) {
  if (!tokens.length) return { sent: 0, failed: 0 };

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: data || {},
    android: {
      priority: "high",
      notification: { channelId: CHANNEL_ID },
    },
  });

  const dead = [];
  response.responses.forEach((r, i) => {
    const code = r.error && r.error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      dead.push(tokens[i]);
    }
  });
  await Promise.all(dead.map((t) => db.collection("deviceTokens").doc(t).delete()));

  return { sent: response.successCount, failed: response.failureCount };
}

async function logNotification({ customerId, orderId, title, body, result }) {
  await db.collection("notifications").add({
    customerId: customerId || null,
    orderId,
    notificationType: "Push",
    title,
    message: body,
    dateTimeCreated: admin.firestore.FieldValue.serverTimestamp(),
    dateTimeSent: result.sent > 0 ? admin.firestore.FieldValue.serverTimestamp() : null,
    notificationStatus: result.sent > 0 ? "sent" : "failed",
    devicesReached: result.sent,
    retryCount: 0,
  });
}

// ---- Customer: push when the order status changes ----
exports.notifyCustomerOnOrderStatus = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    if (before.orderStatus === after.orderStatus) return null;

    const customerName = after.customerName || "Customer";
    let title;
    let body;

    if (
      PROCESSING_STATUSES.includes(after.orderStatus) &&
      !PROCESSING_STATUSES.includes(before.orderStatus)
    ) {
      // Only the first processing step sends a push (not every Sorting/Washing/Drying change)
      title = "Order In Process";
      body = `Hi ${customerName}! Your laundry order #${after.queueNumber} is now being washed.`;
    } else if (READY_STATUSES.includes(after.orderStatus)) {
      title = "Order Ready for Pickup!";
      body = `Hi ${customerName}! Your laundry order #${after.queueNumber} at G A Laundry Shop is ready for pickup. Thank you!`;
    } else if (after.orderStatus === CLAIMED_STATUS) {
      title = "Order Completed";
      body = `Thank you, ${customerName}! Order #${after.queueNumber} has been claimed.`;
    } else {
      return null;
    }

    const tokens = await tokensFor(
      db.collection("deviceTokens").where("customerId", "==", after.customerId)
    );

    let result = { sent: 0, failed: 0 };
    try {
      result = await sendPush(tokens, {
        title,
        body,
        data: { type: "order_update", orderId, status: String(after.orderStatus) },
      });
    } catch (error) {
      functions.logger.error(`Push failed for order ${orderId}`, error);
    }

    await logNotification({ customerId: after.customerId, orderId, title, body, result });

    // Mirror the result onto the order, so staff can see it without opening the notifications collection.
    await change.after.ref.update({
      pushStatus: result.sent > 0 ? "sent" : "failed",
      pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
      pushError: result.sent > 0 ? admin.firestore.FieldValue.delete() : "No device reached for this customer",
    });

    return null;
  });

// ---- Admin: push when a new order comes in ----
exports.notifyAdminsOnNewOrder = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;

    const title = "New Order";
    const body = `${order.customerName || "A customer"} placed order #${order.queueNumber}.`;

    const tokens = await tokensFor(db.collection("deviceTokens").where("role", "==", "admin"));

    try {
      const result = await sendPush(tokens, {
        title,
        body,
        data: { type: "order_alert", orderId },
      });
      await logNotification({ customerId: null, orderId, title, body, result });
    } catch (error) {
      functions.logger.error(`Admin push failed for order ${orderId}`, error);
    }

    return null;
  });
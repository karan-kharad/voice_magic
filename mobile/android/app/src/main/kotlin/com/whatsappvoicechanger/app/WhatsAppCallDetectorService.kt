package com.whatsappvoicechanger.app

import android.app.Notification
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class WhatsAppCallDetectorService : NotificationListenerService() {

    companion object {
        private const val TAG = "WhatsAppCallDetector"
        private const val PKG_WHATSAPP = "com.whatsapp"
        private const val PKG_WHATSAPP_BUSINESS = "com.whatsapp.w4b"
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "WhatsApp Call Notification Listener connected successfully.")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val pkg = sbn.packageName ?: return
        if (pkg != PKG_WHATSAPP && pkg != PKG_WHATSAPP_BUSINESS) return

        val notification = sbn.notification ?: return
        if (isWhatsAppCallNotification(notification)) {
            Log.i(TAG, "Detected active WhatsApp call! sbn id=${sbn.id}, category=${notification.category}")

            if (OverlayPreferences.isAutoPopupEnabled(this)) {
                if (Settings.canDrawOverlays(this)) {
                    FloatingCallOverlayService.show(this)
                } else {
                    Log.w(TAG, "Cannot show floating overlay: SYSTEM_ALERT_WINDOW permission not granted.")
                }
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        if (sbn == null) return

        val pkg = sbn.packageName ?: return
        if (pkg != PKG_WHATSAPP && pkg != PKG_WHATSAPP_BUSINESS) return

        val notification = sbn.notification ?: return
        if (isWhatsAppCallNotification(notification) || notification.category == Notification.CATEGORY_CALL) {
            Log.i(TAG, "WhatsApp call ended/dismissed. Hiding floating overlay.")
            FloatingCallOverlayService.hide(this)
        }
    }

    private fun isWhatsAppCallNotification(notification: Notification): Boolean {
        // 1. Direct Category Check
        if (notification.category == Notification.CATEGORY_CALL) {
            return true
        }

        // 2. Extras Text Check
        val extras = notification.extras
        val title = extras?.getString(Notification.EXTRA_TITLE)?.lowercase() ?: ""
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.lowercase() ?: ""
        val subText = extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.lowercase() ?: ""

        if (title.contains("call") || title.contains("ringing") || title.contains("incoming") ||
            text.contains("call") || text.contains("ringing") || text.contains("incoming") ||
            subText.contains("call") || subText.contains("ongoing")) {
            return true
        }

        // 3. Action Check (Call notifications feature Accept/Decline or Answer/End)
        val actions = notification.actions
        if (actions != null) {
            for (action in actions) {
                val actionTitle = action.title?.toString()?.lowercase() ?: ""
                if (actionTitle.contains("decline") ||
                    actionTitle.contains("answer") ||
                    actionTitle.contains("accept") ||
                    actionTitle.contains("end call")) {
                    return true
                }
            }
        }

        return false
    }
}

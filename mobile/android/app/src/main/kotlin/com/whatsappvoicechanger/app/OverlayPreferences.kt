package com.whatsappvoicechanger.app

import android.content.Context
import android.content.SharedPreferences

object OverlayPreferences {
    private const val PREF_NAME = "whatsapp_voice_overlay_prefs"
    private const val KEY_AUTO_POPUP = "auto_popup_enabled"
    private const val KEY_VOICE_CHANGER_ACTIVE = "voice_changer_active"
    private const val KEY_SELECTED_PRESET = "selected_preset"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    fun isAutoPopupEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_AUTO_POPUP, true)
    }

    fun setAutoPopupEnabled(context: Context, enabled: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_AUTO_POPUP, enabled).apply()
    }

    fun isVoiceChangerActive(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_VOICE_CHANGER_ACTIVE, false)
    }

    fun setVoiceChangerActive(context: Context, active: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_VOICE_CHANGER_ACTIVE, active).apply()
    }

    fun getSelectedPreset(context: Context): String {
        return getPrefs(context).getString(KEY_SELECTED_PRESET, "Robot") ?: "Robot"
    }

    fun setSelectedPreset(context: Context, preset: String) {
        getPrefs(context).edit().putString(KEY_SELECTED_PRESET, preset).apply()
    }
}

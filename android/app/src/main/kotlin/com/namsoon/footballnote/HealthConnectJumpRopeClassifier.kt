package com.namsoon.footballnote

import java.util.Locale

internal object HealthConnectJumpRopeClassifier {
    const val samsungHealthPackageName = "com.sec.android.app.shealth"

    fun isSamsungHealthSource(packageName: String): Boolean {
        return packageName == samsungHealthPackageName
    }

    fun containsJumpRopeKeyword(value: String?): Boolean {
        if (value.isNullOrBlank()) return false
        val compact = value
            .lowercase(Locale.US)
            .replace(Regex("[\\s_\\-]"), "")
        return compact.contains("jumprope") ||
            compact.contains("jumpingrope") ||
            compact.contains("skippingrope") ||
            compact.contains("skipping") ||
            compact.contains("줄넘기") ||
            compact.contains("縄跳び") ||
            compact.contains("なわとび") ||
            compact.contains("跳绳")
    }
}

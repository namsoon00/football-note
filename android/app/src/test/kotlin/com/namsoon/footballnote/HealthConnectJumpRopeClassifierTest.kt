package com.namsoon.footballnote

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HealthConnectJumpRopeClassifierTest {
    @Test
    fun acceptsOnlySamsungHealthAsSource() {
        assertTrue(
            HealthConnectJumpRopeClassifier.isSamsungHealthSource(
                "com.sec.android.app.shealth",
            ),
        )
        assertFalse(
            HealthConnectJumpRopeClassifier.isSamsungHealthSource(
                "com.google.android.apps.fitness",
            ),
        )
    }

    @Test
    fun recognizesSupportedJumpRopeLabels() {
        assertTrue(
            HealthConnectJumpRopeClassifier.containsJumpRopeKeyword(
                "Jump rope workout",
            ),
        )
        assertTrue(
            HealthConnectJumpRopeClassifier.containsJumpRopeKeyword("줄넘기"),
        )
        assertTrue(
            HealthConnectJumpRopeClassifier.containsJumpRopeKeyword("縄跳び"),
        )
        assertFalse(
            HealthConnectJumpRopeClassifier.containsJumpRopeKeyword("Running"),
        )
    }
}

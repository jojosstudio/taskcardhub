package de.jojosstudio.taskcard_hub_flutter

import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import androidx.lifecycle.lifecycleScope
import com.clerk.api.Clerk
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.data?.let(::scheduleClerkCallback)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.data?.let(::scheduleClerkCallback)
    }

    private fun scheduleClerkCallback(uri: Uri) {
        Log.i("TaskcardHub", "Clerk callback received: $uri")
        lifecycleScope.launch {
            delay(2000)
            try {
                val result = Clerk.auth.handleMagicLinkDeepLink(uri)
                Log.i("TaskcardHub", "Clerk callback handled: $result")
            } catch (error: Throwable) {
                Log.e("TaskcardHub", "Clerk callback could not be completed", error)
            }
        }
    }
}

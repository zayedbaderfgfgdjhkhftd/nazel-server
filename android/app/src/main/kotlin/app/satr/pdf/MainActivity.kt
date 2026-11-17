package app.satr.pdf

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.StatFs
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Hosts Flutter and a tiny platform bridge:
 *  - totalMemory / freeSpace: device-aware size limits and the storage indicator
 *  - share target: files shared to Satr (SEND / SEND_MULTIPLE / VIEW) are copied
 *    into the app cache and handed to Dart. The originals are never modified.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "app.satr.pdf/platform"
    private var channel: MethodChannel? = null
    private val io = Executors.newSingleThreadExecutor()
    private var pending: List<Map<String, String?>> = emptyList()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "totalMemory" -> {
                    val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val info = ActivityManager.MemoryInfo()
                    am.getMemoryInfo(info)
                    result.success(info.totalMem)
                }
                "freeSpace" -> result.success(StatFs(filesDir.path).availableBytes)
                "takeSharedFiles" -> {
                    result.success(pending)
                    pending = emptyList()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) handleIntent(intent, initial = true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, initial = false)
    }

    private fun urisOf(intent: Intent): List<Uri> = when (intent.action) {
        Intent.ACTION_SEND -> listOfNotNull(
            if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
        )
        Intent.ACTION_SEND_MULTIPLE ->
            (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else @Suppress("DEPRECATION") intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)) ?: emptyList()
        Intent.ACTION_VIEW -> listOfNotNull(intent.data)
        else -> emptyList()
    }

    private fun handleIntent(intent: Intent?, initial: Boolean) {
        if (intent == null) return
        val uris = urisOf(intent)
        if (uris.isEmpty()) return
        io.execute {
            val files = uris.take(50).mapNotNull { copyToCache(it) }
            runOnUiThread {
                if (initial || channel == null) {
                    pending = pending + files
                } else {
                    channel?.invokeMethod("sharedFiles", files)
                }
            }
        }
    }

    private fun displayName(uri: Uri): String {
        var name: String? = null
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) name = c.getString(0)
            }
        } catch (_: Exception) {
        }
        return (name ?: uri.lastPathSegment ?: "file").replace(Regex("[\\\\/:*?\"<>|]"), "_")
    }

    private fun copyToCache(uri: Uri): Map<String, String?>? = try {
        val dir = File(cacheDir, "shared").apply { mkdirs() }
        val name = displayName(uri)
        val target = File(dir, "${System.nanoTime()}_$name")
        contentResolver.openInputStream(uri)?.use { input ->
            target.outputStream().use { output -> input.copyTo(output) }
        } ?: return null
        mapOf("path" to target.absolutePath, "name" to name, "mime" to contentResolver.getType(uri))
    } catch (_: Exception) {
        null
    }
}

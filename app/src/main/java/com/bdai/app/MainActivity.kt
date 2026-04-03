package com.bdai.app

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.util.Base64
import android.webkit.*
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.webkit.WebSettingsCompat
import androidx.webkit.WebViewFeature
import com.bdai.app.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var webView: WebView
    private var filePathCallback: ValueCallback<Array<Uri>>? = null
    private var permissionCallback: PermissionRequest? = null

    private val filePickerLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val uris = if (result.resultCode == Activity.RESULT_OK) {
            result.data?.clipData?.let { clip ->
                Array(clip.itemCount) { clip.getItemAt(it).uri }
            } ?: result.data?.data?.let { arrayOf(it) } ?: emptyArray()
        } else emptyArray()
        filePathCallback?.onReceiveValue(uris)
        filePathCallback = null
    }

    private val permLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { grants ->
        if (grants.values.all { it }) {
            permissionCallback?.grant(permissionCallback!!.resources)
        } else {
            permissionCallback?.deny()
        }
        permissionCallback = null
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        webView = binding.webView

        // Fix Bug 5: use OnBackPressedDispatcher instead of deprecated onBackPressed
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (webView.canGoBack()) webView.goBack()
                else finish()
            }
        })

        setupWebView()
        webView.loadUrl("file:///android_asset/www/index.html")
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            allowFileAccess = true
            allowContentAccess = true
            mediaPlaybackRequiresUserGesture = false
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            useWideViewPort = true
            loadWithOverviewMode = true
            cacheMode = WebSettings.LOAD_DEFAULT
        }

        if (WebViewFeature.isFeatureSupported(WebViewFeature.ALGORITHMIC_DARKENING)) {
            WebSettingsCompat.setAlgorithmicDarkeningAllowed(webView.settings, false)
        }

        webView.addJavascriptInterface(AndroidBridge(), "AndroidBridge")

        webView.webChromeClient = object : WebChromeClient() {
            override fun onShowFileChooser(
                webView: WebView?,
                filePathCallback: ValueCallback<Array<Uri>>?,
                fileChooserParams: FileChooserParams?
            ): Boolean {
                this@MainActivity.filePathCallback = filePathCallback
                val intent = fileChooserParams?.createIntent()
                    ?: Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "*/*"
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    }
                filePickerLauncher.launch(intent)
                return true
            }

            override fun onPermissionRequest(request: PermissionRequest?) {
                request ?: return
                val needed = request.resources.filter {
                    it == PermissionRequest.RESOURCE_AUDIO_CAPTURE ||
                    it == PermissionRequest.RESOURCE_VIDEO_CAPTURE
                }.toTypedArray()
                if (needed.isEmpty()) { request.deny(); return }
                val perms = mutableListOf<String>()
                if (needed.contains(PermissionRequest.RESOURCE_AUDIO_CAPTURE))
                    perms.add(Manifest.permission.RECORD_AUDIO)
                val allGranted = perms.all {
                    ContextCompat.checkSelfPermission(this@MainActivity, it) ==
                        PackageManager.PERMISSION_GRANTED
                }
                if (allGranted) request.grant(needed)
                else { permissionCallback = request; permLauncher.launch(perms.toTypedArray()) }
            }
        }

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView?, request: WebResourceRequest?
            ): Boolean {
                val url = request?.url?.toString() ?: return false
                return if (url.startsWith("file://") || url.startsWith("http://103.7.4.121")) {
                    false
                } else {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                    true
                }
            }
        }
    }

    inner class AndroidBridge {
        @JavascriptInterface
        fun showToast(msg: String) {
            runOnUiThread {
                Toast.makeText(this@MainActivity, msg, Toast.LENGTH_SHORT).show()
            }
        }

        @JavascriptInterface
        fun getImageAsBase64(uriStr: String): String {
            return try {
                val uri = Uri.parse(uriStr)
                val stream = contentResolver.openInputStream(uri) ?: return ""
                val bytes = stream.readBytes()
                stream.close()
                Base64.encodeToString(bytes, Base64.NO_WRAP)
            } catch (e: Exception) { "" }
        }

        @JavascriptInterface
        fun vibrate() {
            @Suppress("DEPRECATION")
            val v = getSystemService(VIBRATOR_SERVICE) as? android.os.Vibrator
            v?.vibrate(
                android.os.VibrationEffect.createOneShot(
                    40, android.os.VibrationEffect.DEFAULT_AMPLITUDE
                )
            )
        }

        @JavascriptInterface
        fun getAppVersion(): String = "1.0.0"
    }

    override fun onPause() { super.onPause(); webView.onPause() }
    override fun onResume() { super.onResume(); webView.onResume() }
    override fun onDestroy() { webView.destroy(); super.onDestroy() }
}

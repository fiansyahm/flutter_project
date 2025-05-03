package com.example.myexambrowser

import android.os.Bundle
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import com.example.myexambrowser.databinding.ActivityUrlBinding

class UrlActivity : AppCompatActivity() {
    private lateinit var binding: ActivityUrlBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityUrlBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.webView.apply {
            settings.javaScriptEnabled = true
            webViewClient = WebViewClient()
            intent.getStringExtra("URL")?.let { loadUrl(it) }
        }
    }
}
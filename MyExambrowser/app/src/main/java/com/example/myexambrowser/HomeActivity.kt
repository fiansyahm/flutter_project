package com.example.myexambrowser

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.myexambrowser.databinding.ActivityHomeBinding

class HomeActivity : AppCompatActivity() {
    private lateinit var binding: ActivityHomeBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityHomeBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.openUrlButton.setOnClickListener {
            val url = binding.urlEditText.text.toString().trim()
            if (url.isNotEmpty()) {
                val intent = Intent(this, UrlActivity::class.java).apply {
                    putExtra("URL", url)
                }
                startActivity(intent)
            } else {
                Toast.makeText(this, "Masukkan URL terlebih dahulu", Toast.LENGTH_SHORT).show()
            }
        }

        binding.scanQrButton.setOnClickListener {
            val intent = Intent(this, QRScanActivity::class.java)
            startActivityForResult(intent, 1)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1 && resultCode == RESULT_OK) {
            data?.getStringExtra("QR_RESULT")?.let {
                binding.urlEditText.setText(it)
            }
        }
    }
}
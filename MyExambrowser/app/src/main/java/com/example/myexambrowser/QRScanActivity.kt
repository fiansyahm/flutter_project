package com.example.myexambrowser

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.myexambrowser.databinding.ActivityQrScanBinding
import com.google.zxing.integration.android.IntentIntegrator
import com.google.zxing.integration.android.IntentResult

class QRScanActivity : AppCompatActivity() {
    private lateinit var binding: ActivityQrScanBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityQrScanBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Memulai scan QR
        IntentIntegrator(this).apply {
            setDesiredBarcodeFormats(IntentIntegrator.QR_CODE)
            setPrompt("Scan QR Code")
            initiateScan()
        }

        binding.galleryButton.setOnClickListener {
            Toast.makeText(this, "Fitur galeri belum diimplementasikan", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val result = IntentIntegrator.parseActivityResult(requestCode, resultCode, data)
        if (result != null) {
            result.contents?.let { scanResult ->
                if (scanResult.startsWith("http")) {
                    val intent = Intent().apply {
                        putExtra("QR_RESULT", scanResult)
                    }
                    setResult(RESULT_OK, intent)
                    finish()
                }
            } ?: Toast.makeText(this, "Scan dibatalkan", Toast.LENGTH_SHORT).show()
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
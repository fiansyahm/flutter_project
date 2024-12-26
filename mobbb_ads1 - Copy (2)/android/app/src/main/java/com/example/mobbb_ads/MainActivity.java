package com.example.mobbb_ads;

import android.os.Bundle;
import android.os.Handler;
import android.widget.LinearLayout;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.MobileAds;
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    private AdView mAdView;
    private Handler adHandler;
    private Runnable adRunnable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Inisialisasi Mobile Ads SDK
        MobileAds.initialize(this);

        // Membuat layout untuk iklan
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);

        // Membuat AdView untuk banner
        mAdView = new AdView(this);
        mAdView.setAdSize(AdSize.BANNER);
        mAdView.setAdUnitId("ca-app-pub-9687530652502444/4022392139");  // Ganti dengan ID iklan Anda

        // Membuat permintaan iklan dan memuat iklan
        loadAd();

        // Menambahkan AdView ke layout
        layout.addView(mAdView);

        // Menambahkan layout ke tampilan yang sudah ada
        addContentView(layout, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        ));

        // Handler untuk memuat ulang iklan setiap 30 detik
        adHandler = new Handler();
        adRunnable = new Runnable() {
            @Override
            public void run() {
                loadAd(); // Memuat ulang iklan
                adHandler.postDelayed(this, 30000); // Ulangi setiap 30 detik
            }
        };
        adHandler.postDelayed(adRunnable, 30000); // Mulai ulang setelah 30 detik
    }

    // Method untuk memuat iklan
    private void loadAd() {
        if (mAdView != null) {
            AdRequest adRequest = new AdRequest.Builder().build();
            mAdView.loadAd(adRequest);
        }
    }

    @Override
    protected void onDestroy() {
        if (mAdView != null) {
            mAdView.destroy();
        }
        if (adHandler != null) {
            adHandler.removeCallbacks(adRunnable); // Hentikan Runnable saat Activity dihancurkan
        }
        super.onDestroy();
    }
}

package com.example.mobbb_ads;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.MobileAds;
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    private AdView mAdView;

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
        mAdView.setAdUnitId("ca-app-pub-3940256099942544/6300978111");  // Ganti dengan ID iklan Anda

        // Membuat permintaan iklan dan memuat iklan
        AdRequest adRequest = new AdRequest.Builder().build();
        mAdView.loadAd(adRequest);

        // Menambahkan AdView ke layout
        layout.addView(mAdView);

        // Membuat tombol untuk menutup tampilan tambahan
        Button closeButton = new Button(this);
        closeButton.setText("Close");

        // Menambahkan listener untuk tombol "Close"
        closeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Menutup tampilan tambahan
                removeAdView();
            }
        });

        // Menambahkan tombol ke layout
        layout.addView(closeButton);

        // Menambahkan layout ke tampilan yang sudah ada
        addContentView(layout, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        ));
    }

    private void removeAdView() {
        // Menutup atau menghapus tampilan AdView
        if (mAdView != null) {
            ((LinearLayout) mAdView.getParent()).removeView(mAdView);
        }
    }

    @Override
    protected void onDestroy() {
        if (mAdView != null) {
            mAdView.destroy();
        }
        super.onDestroy();
    }
}

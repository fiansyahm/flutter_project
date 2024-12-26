package com.example.mobbb_ads;

import android.os.Bundle;
import android.widget.LinearLayout;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.rewarded.RewardItem;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.gms.ads.LoadAdError;
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    private AdView mAdView;
    private InterstitialAd mInterstitialAd;
    private RewardedAd mRewardedAd;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Inisialisasi Mobile Ads SDK
        MobileAds.initialize(this);

        // Membuat layout untuk banner
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);

        // Membuat AdView untuk banner
        mAdView = new AdView(this);
        mAdView.setAdSize(AdSize.BANNER);
        mAdView.setAdUnitId("ca-app-pub-9687530652502444/4022392139"); // Ganti dengan ID iklan Anda
        layout.addView(mAdView);

        // Menambahkan layout ke tampilan
        addContentView(layout, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        ));

        // Memuat iklan banner
        loadBannerAd();

        // Memuat iklan interstitial
        loadInterstitialAd();

        // Memuat iklan rewarded
        loadRewardedAd();
    }

    private void loadBannerAd() {
        if (mAdView != null) {
            AdRequest adRequest = new AdRequest.Builder().build();
            mAdView.loadAd(adRequest);
        }
    }

    private void loadInterstitialAd() {
        AdRequest adRequest = new AdRequest.Builder().build();
        InterstitialAd.load(this, "ca-app-pub-9687530652502444/6672574386", adRequest,
                new InterstitialAdLoadCallback() {
                    @Override
                    public void onAdLoaded(InterstitialAd interstitialAd) {
                        mInterstitialAd = interstitialAd;
                        // Tampilkan iklan interstitial segera setelah dimuat
                        mInterstitialAd.show(MainActivity.this);
                    }

                    @Override
                    public void onAdFailedToLoad(LoadAdError loadAdError) {
                        mInterstitialAd = null;
                    }
                });
    }

    private void loadRewardedAd() {
        AdRequest adRequest = new AdRequest.Builder().build();
        RewardedAd.load(this, "ca-app-pub-9687530652502444/3798999034", adRequest,
                new RewardedAdLoadCallback() {
                    @Override
                    public void onAdLoaded(RewardedAd rewardedAd) {
                        mRewardedAd = rewardedAd;
                        // Tampilkan iklan rewarded segera setelah dimuat
                        mRewardedAd.show(MainActivity.this, rewardItem -> {
                            int rewardAmount = rewardItem.getAmount();
                            String rewardType = rewardItem.getType();
                            // Tambahkan logika pemberian hadiah di sini
                        });
                    }

                    @Override
                    public void onAdFailedToLoad(LoadAdError loadAdError) {
                        mRewardedAd = null;
                    }
                });
    }

    @Override
    protected void onDestroy() {
        if (mAdView != null) {
            mAdView.destroy();
        }
        super.onDestroy();
    }
}

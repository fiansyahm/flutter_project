package com.banksampah.digitalamanah;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.ContextWrapper;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

import androidx.appcompat.app.AppCompatDelegate;

import com.pixplicity.easyprefs.library.Prefs;

import java.io.File;
import java.text.NumberFormat;
import java.util.Locale;

public class BaseApplication extends Application {
    private static BaseApplication mInstance;
    private static Context context;
    private Activity activity = null;

    public static synchronized BaseApplication getInstance() {
        return mInstance;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO);

        new Prefs.Builder()
                .setContext(this)
                .setMode(ContextWrapper.MODE_PRIVATE)
                .setPrefsName(getPackageName())
                .setUseDefaultSharedPreference(true)
                .build();
//        if (!BuildConfig.DEBUG) {
//        }

        BaseApplication.context = getApplicationContext();

        mInstance = this;

    }

    public static Context getAppContext() {
        return BaseApplication.context;
    }

    public Activity getActivity() {
        return activity;
    }

    public void setActivity(Activity activity) {
        this.activity = activity;
    }

    public static File getCacheDirectory() {
        File cache = context.getCacheDir();

        if (!cache.exists()) {
            cache.mkdirs();
        }

        return cache;
    }

    public static boolean isNetworkConnected() {
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

        NetworkInfo activeNetwork = null;

        if (cm != null) {
            activeNetwork = cm.getActiveNetworkInfo();
        }

        return activeNetwork != null && activeNetwork.isConnectedOrConnecting();
    }

    public static String convertRupiah(int intPrice) {
        Locale localId = new Locale("in", "ID");
        NumberFormat formatter = NumberFormat.getCurrencyInstance(localId);
        String strFormat = formatter.format(intPrice);
        return strFormat;
    }
}

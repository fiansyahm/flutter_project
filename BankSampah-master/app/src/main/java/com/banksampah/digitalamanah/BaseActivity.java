package com.banksampah.digitalamanah;

import androidx.appcompat.app.AppCompatActivity;

import android.app.Activity;
import android.content.SharedPreferences;
import android.icu.text.SymbolTable;
import android.os.Bundle;
import android.preference.PreferenceManager;

public class BaseActivity extends AppCompatActivity {

    private static String KEY_THEME = "Theme";
    public static final String INDIGO = "indigo";
    public static final String PINK = "pink";
    public static final String TEAL = "teal";
    public static final String CYAN = "cyan";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setTheme(getSavedTheme());
        setContentView(R.layout.activity_base);

    }

    public void switchTheme(String value) {
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
        SharedPreferences.Editor editor = preferences.edit();
        editor.putString("theme", value);
        editor.commit();
        recreate();
    }


    public int getSavedTheme() {
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
        String theme = preferences.getString("theme", INDIGO);
        switch (theme) {
            case PINK:
                return R.style.AppTheme_Pink;
            case TEAL:
                return R.style.AppTheme_Teal;
            case CYAN:
                return R.style.AppTheme_Cyan;
            case INDIGO:
            default:
                return R.style.AppTheme_Indigo;
        }
    }

}
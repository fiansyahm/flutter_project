package com.banksampah.digitalamanah;

import static android.content.Intent.FLAG_ACTIVITY_NEW_TASK;

import androidx.appcompat.app.AppCompatActivity;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.util.Base64;
import android.util.Log;

import com.bumptech.glide.Glide;
import com.esafirm.imagepicker.features.ImagePicker;
import com.esafirm.imagepicker.features.ReturnMode;
import com.esafirm.imagepicker.model.Image;
import com.pixplicity.easyprefs.library.Prefs;
import com.banksampah.digitalamanah.databinding.ActivitySettingBinding;
import com.banksampah.digitalamanah.util.ProgressDialogUtil;

import java.io.ByteArrayOutputStream;
import java.io.File;

public class SettingActivity extends BaseActivity {

    ActivitySettingBinding binding;
    Uri pathLogo = null;
    Uri pathBg = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySettingBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);

        setSupportActionBar(binding.toolbar.toolbar);
        getSupportActionBar().setTitle("Setting");
        binding.toolbar.toolbar.setNavigationOnClickListener(v->{
            setResult(RESULT_OK);
            finish();
        });

        binding.inputUrl.setText(preferences.getString("url", ""));
        binding.inputName.setText(preferences.getString("name", "Apps"));
        binding.inputAboutUs.setText(preferences.getString("about", ""));
        binding.inputPassword.setText(preferences.getString("password", ""));

        binding.btnPickLogo.setOnClickListener(v->{
            pickImage(1);
        });

        binding.btnPickBg.setOnClickListener(v->{
            pickImage(0);
        });

        String logoUri = preferences.getString("logo", "");
        String backgroundUri = preferences.getString("background", "");

        Glide.with(this).load(Uri.parse(logoUri))
                .error(R.drawable.ic_logo).into(binding.imgLogo);

        Glide.with(this).load(Uri.parse(backgroundUri))
                .error(R.drawable.ic_logo).into(binding.imgBg);

        binding.btnSave.setOnClickListener(v->{
            SharedPreferences.Editor editor = preferences.edit();
            editor.putString("url", binding.inputUrl.getText().toString());
            editor.putString("name", binding.inputName.getText().toString());
            editor.putString("about", binding.inputAboutUs.getText().toString());
            if (!binding.inputPassword.getText().toString().equalsIgnoreCase("")){
                editor.putString("password", binding.inputPassword.getText().toString());
            }
            if (pathLogo != null){
                // Saves image URI as string to Default Shared Preferences
                editor.putString("logo", String.valueOf(pathLogo));
            }

            if (pathBg != null){
                editor.putString("background", String.valueOf(pathBg));
            }
            editor.commit();
            triggerRebirth(SettingActivity.this);
        });

        binding.LayoutTeal.setOnClickListener(v->{
            switchTheme(TEAL);
        });

        binding.LayoutCyan.setOnClickListener(v->{
            switchTheme(CYAN);
        });

        binding.LayoutIndigo.setOnClickListener(v->{
            switchTheme(INDIGO);
        });

        binding.LayoutPink.setOnClickListener(v->{
            switchTheme(PINK);
        });
    }

    public static void triggerRebirth(Context context) {
        PackageManager packageManager = context.getPackageManager();
        Intent intent = packageManager.getLaunchIntentForPackage(context.getPackageName());
        ComponentName componentName = intent.getComponent();
        Intent mainIntent = Intent.makeRestartActivityTask(componentName);
        context.startActivity(mainIntent);
        Runtime.getRuntime().exit(0);
    }

    void pickImage(int code){
        ImagePicker.create(SettingActivity.this)
            .showCamera(true)
            .returnMode(ReturnMode.ALL)
            .single()
            .toolbarImageTitle("Tap to select") // image selection title
            .toolbarDoneButtonText("DONE")
            .toolbarArrowColor(Color.RED)
            .start(code);
    }

    @Override
    public void onActivityResult(int requestCode, final int resultCode, Intent data) {
        Image images = ImagePicker.getFirstImageOrNull(data);
        if (requestCode == 1) {
            if (images != null) {
                ProgressDialogUtil.showLoading(this);
                File file = new File(images.getPath());
                pathLogo = Uri.fromFile(file);
                Glide.with(this).load(pathLogo).into(binding.imgLogo);
//                Bitmap b = BitmapFactory.decodeFile(images.getPath());
//                Prefs.putString("LOGO", encodeToBase64(b));
            }
        }else{
            if (images != null) {
                ProgressDialogUtil.showLoading(this);
                File file = new File(images.getPath());
                pathBg = Uri.fromFile(file);
                Glide.with(this).load(pathBg).into(binding.imgBg);
//                Bitmap b = BitmapFactory.decodeFile(images.getPath());
//                Prefs.putString("BG", encodeToBase64(b));
            }
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        setResult(RESULT_OK);
        finish();
    }
}
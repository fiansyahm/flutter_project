package com.banksampah.digitalamanah;

import static com.banksampah.digitalamanah.fragment.WebviewFragment.hasPermissions;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import android.Manifest;
import android.app.AppOpsManager;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.preference.PreferenceManager;
import android.provider.Settings;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import com.bumptech.glide.Glide;
import com.pixplicity.easyprefs.library.Prefs;
import com.banksampah.digitalamanah.databinding.ActivitySplashScreenBinding;
import com.banksampah.digitalamanah.util.PermissionManager;
import com.banksampah.digitalamanah.util.ToastUtil;

import java.io.FileNotFoundException;
import java.io.InputStream;

public class SplashScreenActivity extends BaseActivity {

    ActivitySplashScreenBinding binding;
    private final String TAG = "sniki";
    boolean hasDenied = false, isOpenSetting = false;
    int permissionNeeded = 0;
    private final int PERMISSION_ALL = 1;
    private PermissionManager permissionManager;
    String[] PERMISSIONS = {
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
            android.Manifest.permission.CAMERA,
            Manifest.permission.ACCESS_FINE_LOCATION,
    };

    @Override
    protected void onResume() {
        super.onResume();
        if (isOpenSetting) {
            if(!hasPermissions(this, PERMISSIONS)) { //false
                Log.d(TAG, "onResume: minta izin");
                ActivityCompat.requestPermissions(this, PERMISSIONS, PERMISSION_ALL);
            } else {
                startActivity(new Intent(SplashScreenActivity.this, MainActivity.class));
                finish();
            }
            isOpenSetting = false;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySplashScreenBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
        String logoUri = preferences.getString("logo", "");
        String backgroundUri = preferences.getString("background", "");
        permissionManager = new PermissionManager(this);

        if(!hasPermissions(this, PERMISSIONS)) { //false
            Log.d(TAG, "onCreate: minta izin");
            ActivityCompat.requestPermissions(this, PERMISSIONS, PERMISSION_ALL);
        } else {
            Log.d(TAG, "onCreate: go to main activity");
            new Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    startActivity(new Intent(SplashScreenActivity.this, MainActivity.class));
                    finish();
                }
            }, 3000);
        }
//
//        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.READ_EXTERNAL_STORAGE}, 1);
//        }
//        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
//        }
//        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA}, 1);
//        }
//        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
//        }


        if (!backgroundUri.equalsIgnoreCase("")){
            Drawable yourDrawable;
            try {
                InputStream inputStream = getContentResolver().openInputStream(Uri.parse(backgroundUri));
                yourDrawable = Drawable.createFromStream(inputStream, Uri.parse(backgroundUri).toString() );
            } catch (FileNotFoundException e) {
                yourDrawable = getResources().getDrawable(R.drawable.ic_launcher_background);
            }
            binding.root.setBackground(yourDrawable);

        }

        Glide.with(this).load(Uri.parse(logoUri))
                .error(R.drawable.logo_bsdakbe_removebg_preview).into(binding.imgLogo);


        if (isMockLocationEnabled()){
            Toast.makeText(this, "Mohon matikan fake GPS", Toast.LENGTH_SHORT).show();
            return;
        }

    }

    public static Bitmap decodeToBase64(String input) {
        byte[] decodedByte = Base64.decode(input, 0);
        return BitmapFactory.decodeByteArray(decodedByte, 0, decodedByte.length);
    }

    public boolean isMockLocationEnabled() {
        boolean isMockLocation = false;
        try {
            //if marshmallow
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                AppOpsManager opsManager = (AppOpsManager) getApplicationContext().getSystemService(Context.APP_OPS_SERVICE);
                isMockLocation = (opsManager.checkOp(AppOpsManager.OPSTR_MOCK_LOCATION, android.os.Process.myUid(), BuildConfig.APPLICATION_ID)== AppOpsManager.MODE_ALLOWED);
            } else {
                // in marshmallow this will always return true
                isMockLocation = !android.provider.Settings.Secure.getString(getApplicationContext().getContentResolver(), "mock_location").equals("0");
            }
        } catch (Exception e) {
            return isMockLocation;
        }
        return isMockLocation;
    }

    private void checkRational() {
        Log.d(TAG, "checkRational: running");
        for (String permission: PERMISSIONS) {
            permissionManager.checkPermission(this, permission, new PermissionManager.PermissionAskListener() {
                @Override
                public void onNeedPermission() {
                    Log.d(TAG, "onNeedPermission: jalan");
                    ActivityCompat.requestPermissions(SplashScreenActivity.this, PERMISSIONS, PERMISSION_ALL);
                }

                @Override
                public void onPermissionPreviouslyDenied() {
                    permissionNeeded++;
                    showRationale(getPermissionName(permission));
                }

                @Override
                public void onPermissionPreviouslyDeniedWithNeverAskAgain() {
                    permissionNeeded++;
                    dialogForSettings("Permission Denied", "Now you must allow access " + getPermissionName(permission) + " from settings.");
                }

                @Override
                public void onPermissionGranted() {
                    if (!hasDenied) {
                        startActivity(new Intent(SplashScreenActivity.this, MainActivity.class));
                        finish();
                    }
                }
            });
        }
    }

    private void showRationale(String permission) {
        new AlertDialog.Builder(this).setTitle("Permission Denied").setMessage("Without " + permission + " permission this app is unable to use some feature. Are you sure you want to deny this permission?")
                .setCancelable(false)
                .setNegativeButton("I'M SURE", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        permissionNeeded--;
                        dialog.dismiss();
                        if (permissionNeeded == 0) {
                            startActivity(new Intent(SplashScreenActivity.this, MainActivity.class));
                            finish();
                        }
                    }
                })
                .setPositiveButton("RETRY", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        ActivityCompat.requestPermissions(SplashScreenActivity.this, PERMISSIONS, PERMISSION_ALL);
                        dialog.dismiss();
                    }
                }).show();

    }

    private void dialogForSettings(String title, String msg) {
        new AlertDialog.Builder(this).setTitle(title).setMessage(msg)
                .setCancelable(false)
                .setNegativeButton("NOT NOW", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        permissionNeeded--;
                        dialog.dismiss();
                        if (permissionNeeded == 0) {
                            startActivity(new Intent(SplashScreenActivity.this, MainActivity.class));
                            finish();
                        }
                    }
                })
                .setPositiveButton("SETTINGS", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        goToSettings();
                        dialog.dismiss();
                    }
                }).show();
    }

    private void goToSettings() {
        Intent intent = new Intent();
        intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        Uri uri = Uri.parse("package:" + getPackageName());
        intent.setData(uri);
        startActivity(intent);
        isOpenSetting = true;
    }

    private String getPermissionName(String permission) {
        switch (permission) {
            case Manifest.permission.WRITE_EXTERNAL_STORAGE:
                return "storage";
            case Manifest.permission.CAMERA:
                return "camera";
            case Manifest.permission.ACCESS_FINE_LOCATION:
                return "location";
            default:
                return "this permission";
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
//        switch (requestCode) {
//            case PERMISSION_ALL: {
//                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
//                    Intent i = new Intent(SplashScreenActivity.this, MainActivity.class);
//                    startActivity(i);
//                    finish();
//                } else {
//                    // Permission was denied.......
//                    Toast.makeText(this, "Permission Denied", Toast.LENGTH_SHORT).show();
//                }
//                break;
//            }
//
//        }
        Log.d(TAG, "onRequestPermissionsResult: dipanggil");
        Log.d(TAG, "onRequestPermissionsResult: " + grantResults.length);
        if (requestCode == PERMISSION_ALL) {
            if (grantResults.length > 0) {
                hasDenied = false;
                for (int i = 0; i < permissions.length; i++) {
                    if (grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                        // Permission ini ditolak
                        String deniedPermission = permissions[i];
                        hasDenied = true;
                        Log.d(TAG, "hasDenied true, " + deniedPermission);
                    }
                }
                if (hasDenied) {
                    checkRational();
                } else {
                    Log.d(TAG, "onRequestPermissionsResult: go to main");
                    startActivity(new Intent(SplashScreenActivity.this, MainActivity.class));
                }
            }
        }
    }

}
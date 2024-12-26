package com.banksampah.digitalamanah;

import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.provider.ContactsContract;
import android.util.Log;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.View;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AlertDialog;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;

import com.banksampah.digitalamanah.databinding.ActivityMainBinding;
import com.banksampah.digitalamanah.databinding.NavHeaderLayoutBinding;
import com.banksampah.digitalamanah.fragment.AboutUsFragment;
import com.banksampah.digitalamanah.fragment.LoginFragment;
import com.banksampah.digitalamanah.fragment.ShareBottomSheetFragment;
import com.banksampah.digitalamanah.fragment.WebviewFragment;
import com.banksampah.digitalamanah.util.DrawerLocker;
import com.bumptech.glide.Glide;
import com.google.android.material.navigation.NavigationView;

public class MainActivity extends BaseActivity implements NavigationView.OnNavigationItemSelectedListener, DrawerLocker {

    ActivityMainBinding binding;
    private static final int PICK_CONTACT_REQUEST = 1;
    private static final int PERMISSION_REQUEST_CONTACT=1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);

        setSupportActionBar(binding.toolbar1.toolbar);

        binding.navigationviewId.setNavigationItemSelectedListener(this);

        // Disable Drawer
        binding.getRoot().setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);


        binding.imgRight.setOnClickListener(v-> binding.getRoot().openDrawer(Gravity.LEFT));

        String logoUri = preferences.getString("logo", "");
        View headerView = binding.navigationviewId.getHeaderView(0);
        NavHeaderLayoutBinding headerBinding = NavHeaderLayoutBinding.bind(headerView);
        headerBinding.navHeaderNameId.setText(preferences.getString("name", "Apps"));
        Glide.with(this).load(Uri.parse(logoUri))
                .error(R.drawable.ic_logo).into(headerBinding.navHeaderCircleimageviewId);

        toggleDrawer();
        initializeDefaultFragment(savedInstanceState);
    }

    /**
     * Checks if the savedInstanceState is null - onCreate() is ran
     * If so, display fragment of navigation drawer menu at position itemIndex and
     * set checked status as true
     */
    private void initializeDefaultFragment(Bundle savedInstanceState){
        if (savedInstanceState == null){
            MenuItem menuItem = binding.navigationviewId.getMenu().getItem(0).setChecked(true);
            onNavigationItemSelected(menuItem);
        }
    }

    /**
     * Creates an instance of the ActionBarDrawerToggle class:
     * 1) Handles opening and closing the navigation drawer
     * 2) Creates a hamburger icon in the toolbar
     * 3) Attaches listener to open/close drawer on icon clicked and rotates the icon
     */
    private void toggleDrawer() {
        ActionBarDrawerToggle drawerToggle = new ActionBarDrawerToggle(this, binding.getRoot(), binding.toolbar1.toolbar,
                R.string.navigation_drawer_open, R.string.navigation_drawer_close);
        binding.getRoot().addDrawerListener(drawerToggle);
        drawerToggle.syncState();

    }


    @Override
    public boolean onNavigationItemSelected(@NonNull MenuItem menuItem) {
        switch (menuItem.getItemId()){
            case R.id.nav_presensi_id:
                getSupportFragmentManager().beginTransaction().replace(R.id.framelayout_id, new WebviewFragment())
                        .commit();
                closeDrawer();
                break;
            case R.id.nav_login_id:
                getSupportFragmentManager().beginTransaction().replace(R.id.framelayout_id,new LoginFragment())
                        .commit();
                closeDrawer();
                break;

            case R.id.nav_share:
                ShareBottomSheetFragment sheet  = new ShareBottomSheetFragment();
                sheet.show(getSupportFragmentManager(), "ModalBottomSheet");
                closeDrawer();
                break;

            case R.id.nav_about_us:
                AboutUsFragment aboutUsFragment  = new AboutUsFragment();
                aboutUsFragment.show(getSupportFragmentManager(), "AboutUsDialog");
                closeDrawer();
                break;


            case R.id.nav_exit:
                new AlertDialog.Builder(this)
                        .setTitle("Konfirmasi")
                        .setMessage("Apakah anda mau keluar ? ")
                        .setPositiveButton(android.R.string.yes, (dialog, whichButton) -> {
                            dialog.dismiss();
                            finishAffinity();
                        })
                        .setNegativeButton(android.R.string.no, null).show();
                break;
        }
        return true;
    }

    /**
     * Checks if the navigation drawer is open - if so, close it
     */
    private void closeDrawer(){
        if (binding.getRoot().isDrawerOpen(GravityCompat.START)){
            binding.getRoot().closeDrawer(GravityCompat.START);
        }
    }

    @Override
    public void setDrawerLocked(boolean shouldLock) {
        if(shouldLock){
            getSupportActionBar().hide();
        }else{
            getSupportActionBar().show();
        }

    }


    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == PERMISSION_REQUEST_CONTACT) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Jika izin diberikan, buka Contact Picker
                Toast.makeText(this, "Permission accept access contacts.", Toast.LENGTH_SHORT).show();
//                openContactPicker();
            } else {
                // Tampilkan pesan jika izin ditolak
                Toast.makeText(this, "Permission Denied! Cannot access contacts.", Toast.LENGTH_SHORT).show();
            }
        }
    }

    // Open the contact picker using an Intent
    private void openContactPicker() {
        Intent intent = new Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI);
        startActivityForResult(intent, PICK_CONTACT_REQUEST);
    }

}
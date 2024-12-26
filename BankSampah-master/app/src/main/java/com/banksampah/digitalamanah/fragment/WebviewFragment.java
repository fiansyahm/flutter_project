package com.banksampah.digitalamanah.fragment;

import static android.content.Context.DOWNLOAD_SERVICE;
import static java.lang.System.currentTimeMillis;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.DownloadManager;
import android.app.ProgressDialog;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.preference.PreferenceManager;
import android.provider.MediaStore;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.DownloadListener;
import android.webkit.GeolocationPermissions;
import android.webkit.PermissionRequest;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;
import androidx.fragment.app.Fragment;

import com.banksampah.digitalamanah.R;
import com.banksampah.digitalamanah.databinding.FragmentWebviewBinding;
import com.banksampah.digitalamanah.util.BackPress;
import com.banksampah.digitalamanah.util.DrawerLocker;

import java.io.File;
import java.net.URISyntaxException;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link WebviewFragment#newInstance} factory method to
 * create an instance of getActivity()() fragment.
 */
public class WebviewFragment extends Fragment implements BackPress {

    FragmentWebviewBinding binding;

    private static final String TAG = "sniki";

    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";

    // TODO: Rename and change types of parameters
    private String mParam1;
    private String mParam2;

    int PERMISSION_ALL = 1;
    String[] PERMISSIONS = {
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
            android.Manifest.permission.CAMERA,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.READ_CONTACTS,
            android.Manifest.permission.READ_CONTACTS
    };

    private static final int FILECHOOSER_RESULTCODE = 1;
    private ValueCallback<Uri> mUploadMessage;
    private Uri mCapturedImageURI = null;

    // Para android 5.0
    private ValueCallback<Uri[]> mFilePathCallback;
    private String rutaFotoCam;


    public WebviewFragment() {
        // Required empty public constructor
    }

    /**
     * Use getActivity()() factory method to create a new instance of
     * getActivity()() fragment using the provided parameters.
     *
     * @param param1 Parameter 1.
     * @param param2 Parameter 2.
     * @return A new instance of fragment WebviewFragment.
     */
    // TODO: Rename and change types and number of parameters
    public static WebviewFragment newInstance(String param1, String param2) {
        WebviewFragment fragment = new WebviewFragment();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mParam1 = getArguments().getString(ARG_PARAM1);
            mParam2 = getArguments().getString(ARG_PARAM2);
        }
    }

    @SuppressLint("UseCompatLoadingForDrawables")
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        CookieSyncManager.createInstance(getActivity());
        ((DrawerLocker)getActivity()).setDrawerLocked(true);

        if(!hasPermissions(getActivity(), PERMISSIONS)){
            ActivityCompat.requestPermissions(getActivity(), PERMISSIONS, PERMISSION_ALL);

        }

        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.READ_EXTERNAL_STORAGE}, 1);
        }
        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
        }
        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.CAMERA}, 1);
        }
        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
        }
        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, 1);
        }
        binding = FragmentWebviewBinding.inflate(getLayoutInflater());
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(getActivity());

        final ProgressDialog progressDialog = new ProgressDialog(getActivity(), R.style.NewDialog);
        progressDialog.setIndeterminateDrawable(getResources().getDrawable(R.drawable.loading, null));
        progressDialog.setCancelable(false);

        if(binding.webview != null){


            binding.webview.getSettings().setLoadsImagesAutomatically(true);
            binding.webview.getSettings().setCacheMode(WebSettings.LOAD_CACHE_ELSE_NETWORK);
            binding.webview.setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);
            binding.webview.requestFocus();
            binding.webview.getSettings().setDatabaseEnabled(true);
            binding.webview.getSettings().setPluginState(WebSettings.PluginState.ON);
            binding.webview.getSettings().setDomStorageEnabled(true);
            binding.webview.getSettings().setAllowFileAccess(true);
            binding.webview.getSettings().setAllowContentAccess(true);
            binding.webview.getSettings().setMediaPlaybackRequiresUserGesture(false);
            binding.webview.getSettings().setGeolocationEnabled(true);
            binding.webview.getSettings().setDefaultTextEncodingName("utf-8");
            binding.webview.loadUrl(preferences.getString("url", "https://bsda-brangene.sumbawabaratkab.go.id/"));
//            binding.webview.loadUrl(preferences.getString("url", "https://google.com/"));
            binding.webview.setWebViewClient(new WebViewClient(){

                @Override
                public void onPageStarted(WebView view, String url, Bitmap favicon) {
                    binding.error.setVisibility(View.GONE);
                    CookieManager.getInstance().setAcceptCookie(true);
                    CookieManager.getInstance().setAcceptThirdPartyCookies(binding.webview, true);
                }

                @Override
                public void onPageFinished(WebView view, String url) {
                    CookieManager.getInstance().flush();
                }

                @Override
                public boolean shouldOverrideUrlLoading(WebView view, String url) {
                    // When user clicks a hyperlink, load in the existing WebView
                    if (url.startsWith("mailto:")) {
                        view.getContext().startActivity(new Intent(Intent.ACTION_SENDTO, Uri.parse(url)));
                    } else if (url.startsWith("tel:")) {
                        view.getContext().startActivity(new Intent(Intent.ACTION_DIAL, Uri.parse(url)));
                    } else if(url.startsWith("sms:") || url.startsWith("whatsapp:") || url.startsWith("intent://") || url.startsWith("fb://")) {
                        try {
                            Context context = view.getContext();
                            Intent intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME);

                            if (intent != null) {
                                view.stopLoading();

                                PackageManager packageManager = context.getPackageManager();
                                ResolveInfo info = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
                                if (info != null) {
                                    Log.d(TAG, "shouldOverrideUrlLoading: info");
                                    context.startActivity(intent);
                                } else {
                                    Log.d(TAG, "shouldOverrideUrlLoading: null");
                                    String fallbackUrl = intent.getStringExtra("browser_fallback_url");
                                    if (fallbackUrl != null) {
                                        Log.d(TAG, "shouldOverrideUrlLoading: fallback");
                                        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(fallbackUrl));
                                        context.startActivity(browserIntent);
                                    } else return false;
                                }
                                return true;
                            }
                        } catch (URISyntaxException e) {
                            Log.e(TAG, "Can't resolve intent://", e);
                        }
                    } else if(url.startsWith("https://maps.google") || url.contains("facebook.com") ||
                            url.startsWith("https://wa.me/") || url.startsWith("whatsapp://") ||
                            url.contains("youtube.com") || url.contains("instagram")){
                        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                        startActivity(intent);
                        return true;
                    }else if(url.contains("geo:")) {
                        Uri gmmIntentUri = Uri.parse(url);
                        Intent mapIntent = new Intent(Intent.ACTION_VIEW, gmmIntentUri);
                        mapIntent.setPackage("com.google.android.apps.maps");
                        if (mapIntent.resolveActivity(getActivity().getPackageManager()) != null) {
                            startActivity(mapIntent);
                        }
                        return true;
                    }
                    return false;
                }

                @Override
                public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                    Log.d(TAG, "onReceivedError: " + error.getDescription());
                    binding.error.setVisibility(View.VISIBLE);
                    binding.refresh.setOnClickListener(view1 -> {
                        binding.webview.reload();
                    });
//                    view.post(() -> view.loadUrl("file:///android_asset/no_internet.html"));
                }
            });

            binding.webview.getSettings().setUseWideViewPort(true);
            binding.webview.getSettings().setJavaScriptEnabled(true);

            binding.webview.setDownloadListener((url, userAgent, contentDisposition, mimetype, contentLength) -> {
                String cookies = CookieManager.getInstance().getCookie(url);

                DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
                request.addRequestHeader("Cookie", cookies);
                request.allowScanningByMediaScanner();
                Environment.getExternalStorageDirectory();
                getActivity().getFilesDir().getPath(); //which returns the internal app files directory path
                request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);

                String name = String.valueOf(System.currentTimeMillis());
                request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "/BankSampahDigital/" + "transaksi_" + name + ".pdf");
                DownloadManager dm = (DownloadManager) getActivity().getSystemService(DOWNLOAD_SERVICE);
                dm.enqueue(request);

                Toast.makeText(getActivity(), "Downloading ...", Toast.LENGTH_LONG).show();
            });

            binding.webview.setWebChromeClient(new WebChromeClient() {

                public void onProgressChanged(WebView view, int progress) {
                    if (progress < 100) {
                        progressDialog.show();
                    }
                    if (progress == 100) {
                        progressDialog.dismiss();
                    }
                }

                @Override
                public void onPermissionRequest(final PermissionRequest request) {
                    final String[] requestedResources = request.getResources();
                    for (String r : requestedResources) {
                        if (r.equals(PermissionRequest.RESOURCE_VIDEO_CAPTURE)) {
                            request.grant(new String[]{PermissionRequest.RESOURCE_VIDEO_CAPTURE});
                            break;
                        }
                    }
                }

                public void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback) {
                    // callback.invoke(String origin, boolean allow, boolean remember);
                    callback.invoke(origin, true, false);
                }

                // en caso de llamar un webview a un file chooser
                public boolean onShowFileChooser(
                        WebView webView, ValueCallback<Uri[]> filePathCallback,
                        WebChromeClient.FileChooserParams fileChooserParams) {
                    if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.CAMERA}, 1);
                    }

                    if (mFilePathCallback != null) {
                        mFilePathCallback.onReceiveValue(null);
                    }
                    mFilePathCallback = filePathCallback;

                    Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                    if (takePictureIntent.resolveActivity(getActivity().getPackageManager()) != null) {

                        // creacion del file para alojar la foto *lollipop
                        File photoFile = null;
                        try {
                            photoFile = createArchivePhoto();
                            takePictureIntent.putExtra("routePhoto", rutaFotoCam);
                        } catch (Exception e) {
                            //System.out.println("fallo al crear la foto");
                            Log.e(TAG, "Gagal memuat gambar", e);
                        }
                        // si tod ok
                        if (photoFile != null) {
                            rutaFotoCam = "file:" + photoFile.getAbsolutePath();
                            Uri photoUri = FileProvider.getUriForFile(
                                    getActivity(),
                                    getActivity().getPackageName() + ".fileprovider",
                                    photoFile
                            );
                            takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoUri);
                        } else {
                            takePictureIntent = null;
                        }
                    }

                    Intent contentSelectionIntent = new Intent(Intent.ACTION_GET_CONTENT);
                    contentSelectionIntent.addCategory(Intent.CATEGORY_OPENABLE);
                    contentSelectionIntent.setType("image/*");

                    Intent[] intentArray;
                    if (takePictureIntent != null) {
                        intentArray = new Intent[]{takePictureIntent};
                    } else {
                        intentArray = new Intent[0];
                    }

                    Intent chooserIntent = new Intent(Intent.ACTION_CHOOSER);
                    chooserIntent.putExtra(Intent.EXTRA_INTENT, contentSelectionIntent);
                    chooserIntent.putExtra(Intent.EXTRA_TITLE, "Choose Image");
                    chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, intentArray);

                    startActivityForResult(chooserIntent, FILECHOOSER_RESULTCODE);

                    return true;
                }

                // crea file para la imagen, necesario en versiones lollipop
                private File createArchivePhoto(){

                    File imageStorageDir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "webviewfiles");

                    if (!imageStorageDir.exists()) {
                        imageStorageDir.mkdirs();
                    }
                    // creacion de imagen, saca substring de la hora en milisegundos le anade extension jpg
                    String hora = String.valueOf(currentTimeMillis());
                    String nombreFoto = hora.substring(8);
                    imageStorageDir = new File(imageStorageDir + File.separator + "imagen_" + nombreFoto + ".jpg");

                    return imageStorageDir;
                }
            });
        }





        if(savedInstanceState!=null){
            binding.webview.restoreState(savedInstanceState);
        }

        requireActivity().getOnBackPressedDispatcher().addCallback(getActivity(), new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                consumeBackPress();
            }
        });

        return binding.getRoot();
    }

    public static boolean hasPermissions(Context context, String... permissions) {
        if (context != null && permissions != null) {
            for (String permission : permissions) {
                if (ActivityCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED) {
                    return false;
                }
            }
        }
        return true;
    }


    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        binding.webview.saveState(outState);

    }

    @Override
    public void onViewStateRestored(@Nullable Bundle savedInstanceState) {
        super.onViewStateRestored(savedInstanceState);
        binding.webview.restoreState(savedInstanceState);
    }

    @Override
    public void onResume() {
        super.onResume();
        CookieSyncManager.getInstance().startSync();
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == FILECHOOSER_RESULTCODE)
        {
            Uri[] results = null;
            //Check if response is positive
            if (resultCode == Activity.RESULT_OK)
            {
                if (null == mFilePathCallback)
                {
                    return;
                }
                if (data == null || data.getData() == null)
                {
                    //Capture Photo if no image available
                    if (rutaFotoCam != null)
                    {
                        results = new Uri[]{Uri.parse(rutaFotoCam)};
                    }
                }
                else
                {
                    String dataString = data.getDataString();
                    if(dataString != null)
                    {
                        results = new Uri[]{Uri.parse(dataString)};
                    }
                }
            }
            mFilePathCallback.onReceiveValue(results);
            mFilePathCallback = null;
        }
    }

    private void consumeBackPress() {
        binding.webview.stopLoading();
        if(binding.webview.canGoBack()){
            binding.webview.goBack();
        } else {
            exitDialog();
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        ((DrawerLocker)getActivity()).setDrawerLocked(true);
    }

    private void exitDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(requireActivity());
        builder.setMessage("Are you sure you want to exit?")
                .setCancelable(false)
                .setPositiveButton("Yes", (dialog, id) -> {
                    requireActivity().moveTaskToBack(true);
                    requireActivity().finish();
                })
                .setNegativeButton("No", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        dialog.cancel();
                    }
                });
        AlertDialog alert = builder.create();
        alert.show();
    }
}
package com.banksampah.digitalamanah.fragment;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.preference.PreferenceManager;
import android.util.Base64;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.bumptech.glide.Glide;
import com.pixplicity.easyprefs.library.Prefs;
import com.banksampah.digitalamanah.R;
import com.banksampah.digitalamanah.SettingActivity;
import com.banksampah.digitalamanah.databinding.FragmentLoginBinding;
import com.banksampah.digitalamanah.util.ToastUtil;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link LoginFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class LoginFragment extends Fragment {

    FragmentLoginBinding binding;

    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";

    // TODO: Rename and change types of parameters
    private String mParam1;
    private String mParam2;

    public LoginFragment() {
        // Required empty public constructor
    }

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param param1 Parameter 1.
     * @param param2 Parameter 2.
     * @return A new instance of fragment LoginFragment.
     */
    // TODO: Rename and change types and number of parameters
    public static LoginFragment newInstance(String param1, String param2) {
        LoginFragment fragment = new LoginFragment();
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

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        binding = FragmentLoginBinding.inflate(getLayoutInflater());
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(getActivity());
        String logoUri = preferences.getString("logo", "");

        Glide.with(this).load(Uri.parse(logoUri))
                .error(R.drawable.ic_logo).into(binding.imgLogo);

        binding.btnLogin.setOnClickListener(v->{
//            if (binding.inputEmail.getText().toString().equalsIgnoreCase("")){
//                ToastUtil.show("Email harap di isi");
//                return;
//            }

            if (binding.inputPassword.getText().toString().equalsIgnoreCase("")){
                ToastUtil.show("Password harap di isi");
                return;
            }

            if (!binding.inputPassword.getText().toString().equalsIgnoreCase(preferences.getString("password","123456"))){
                ToastUtil.show("Password salah");
                return;
            }

            startActivityForResult(new Intent(getActivity(), SettingActivity.class), 1);

        });

        return binding.getRoot();
    }

    public static Bitmap decodeToBase64(String input) {
        byte[] decodedByte = Base64.decode(input, 0);
        return BitmapFactory.decodeByteArray(decodedByte, 0, decodedByte.length);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        if (requestCode == 1) {
            getActivity().recreate();
        }
    }


}
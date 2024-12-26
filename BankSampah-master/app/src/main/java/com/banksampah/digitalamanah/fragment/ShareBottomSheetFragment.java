package com.banksampah.digitalamanah.fragment;

import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;

import androidx.fragment.app.DialogFragment;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;

import com.banksampah.digitalamanah.R;
import com.banksampah.digitalamanah.databinding.FragmentShareBottomSheetBinding;
import com.banksampah.digitalamanah.util.ToastUtil;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link ShareBottomSheetFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class ShareBottomSheetFragment extends DialogFragment {

    FragmentShareBottomSheetBinding binding;

    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";

    // TODO: Rename and change types of parameters
    private String mParam1;
    private String mParam2;

    public ShareBottomSheetFragment() {
        // Required empty public constructor
    }

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param param1 Parameter 1.
     * @param param2 Parameter 2.
     * @return A new instance of fragment ShareBottomSheetFragment.
     */
    // TODO: Rename and change types and number of parameters
    public static ShareBottomSheetFragment newInstance(String param1, String param2) {
        ShareBottomSheetFragment fragment = new ShareBottomSheetFragment();
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
        binding = FragmentShareBottomSheetBinding.inflate(inflater);

        binding.rootTelegram.setOnClickListener(v->{
            Intent whatsappIntent = new Intent(Intent.ACTION_SEND);
            whatsappIntent.setType("text/plain");
            whatsappIntent.setPackage("org.telegram.messenger");
            whatsappIntent.putExtra(Intent.EXTRA_TEXT, "The text you wanted to share");
            try {
                getActivity().startActivity(whatsappIntent);
            } catch (android.content.ActivityNotFoundException ex) {
                ToastUtil.show("Whatsapp have not been installed.");
            }
        });

        binding.rootWhatsapp.setOnClickListener(v->{
            Intent whatsappIntent = new Intent(Intent.ACTION_SEND);
            whatsappIntent.setType("text/plain");
            whatsappIntent.setPackage("com.whatsapp");
            whatsappIntent.putExtra(Intent.EXTRA_TEXT, "The text you wanted to share");
            try {
                getActivity().startActivity(whatsappIntent);
            } catch (android.content.ActivityNotFoundException ex) {
                ToastUtil.show("Whatsapp have not been installed.");
            }
        });


        return binding.getRoot();
    }

    @Override
    public void onStart() {
        super.onStart();
        getDialog().getWindow().setLayout(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }
}
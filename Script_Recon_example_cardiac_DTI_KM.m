
clear all
close all
warning off;

enum=[];
Dcm=[];


%%%%%%%%%%%%%%% UI Management %%%%%%%%%%%%%%%%%%%%%%
UI=UIDiffRecon_KM(true);
disp('Select Folder');
dcm_dir = uigetdir;
cd(dcm_dir);
mkdir([dcm_dir '/Maps'])
if UI.gif_mode
    mkdir([dcm_dir '/Gif'])
end
listing = dir(dcm_dir);

%%
%%%%%%%%%%%%%%% Create Enum and Vol %%%%%%%%%%%%%%%%
[Dcm enum]= AnalyseDataSet_KM(listing);
%[Dcm enum]= AnalyseDataSet_forced_KM(listing, [1],[0 350],[1 1],[20 20]);
enum.dcm_dir=dcm_dir;
enum.nset=1;

save([dcm_dir '/Maps/RAW.mat'],'Dcm','enum');
if UI.gif_mode
    Gif_KM(Dcm, enum, 'Raw')
end

%%
%%%%%%%%%%%%%%% Unmosaic %%%%%%%%%
if UI.mosa_mode && enum.mosa>1
    [Dcm, enum]= Demosa_KM(Dcm, enum);
    save([enum.dcm_dir '/Maps/Demosa.mat'],'Dcm','enum');
    if UI.gif_mode
        Gif_KM(Dcm, enum, 'Unmosaic')
    end
end

%%
%%%%%%%%%%%%%%% Prior Registration %%%%%%%%%
if UI.rigid_mode
    [Dcm]= RigidRegistration_KM2(Dcm, enum);
    save([enum.dcm_dir '/Maps/RigidBefore.mat'],'Dcm','enum');
    if UI.gif_mode
        Gif_KM(Dcm, enum, 'RigidReg')
    end
end

if UI.Nrigid_mode
    [Dcm]= NonRigidRegistration_KM(Dcm, enum);
    save([enum.dcm_dir '/Maps/NonRigid.mat'],'Dcm','enum');
    if UI.gif_mode
        Gif_KM(Dcm, enum, 'NonRigidReg')
    end
end

%%
%%%%%%%%%%%%%%% Zero filling interpolation %%%%%%%%%
if UI.inter_mode
    [Dcm enum]= Interpolation_KM(Dcm, enum);
    save([enum.dcm_dir '/Maps/Interpolation.mat'],'Dcm','enum');
     if UI.gif_mode
        Gif_KM(Dcm, enum, 'Interpolation')
    end
end 

%%
%%%%%%%%%%%%%%% PCA %%%%%%%%%
if UI.pca_mode
    [Dcm ]= VPCA_KM(Dcm,enum,80);
    save([enum.dcm_dir '/Maps/PCA.mat'],'Dcm','DcmB0','enum');
end

%%
%%%%%%%%%%%%%%% tMIP %%%%%%%%%
if UI.tmip_mode
    [Dcm enum]= tMIP_KM(Dcm, enum);
    save([enum.dcm_dir '/Maps/tMIP.mat'],'Dcm','enum');
     if UI.gif_mode
        Gif_KM(Dcm, enum, 'tMIP')
    end
end

%%
%%%%%%%%%%%%%%%% Average %%%%%%%%%
if UI.avg_mode   
    [Dcm enum]= Average_KM(Dcm, enum); 
    save([enum.dcm_dir '/Maps/Average.mat'],'Dcm','enum');
    if UI.gif_mode
        Gif_KM(Dcm, enum, 'Average')
    end
end

%%
%%%%%%%%%%%%%%%% Average and reject %%%%%%%%%
if UI.avg2_mode 
    [Dcm  enum]= Average_and_Reject_KM(Dcm, enum,4e-3);
    save([enum.dcm_dir '/Maps/Average_Reject.mat'],'Dcm','enum');
     if UI.gif_mode
        Gif_KM(Dcm, enum, 'Average_Reject')
    end
end
%%
%%%%%%%%%%%%%%% Registration %%%%%%%%%
if UI.rigid_mode
    [Dcm]= RigidRegistration_KM(Dcm, enum);
    save([enum.dcm_dir '/Maps/RigidAfter.mat'],'Dcm','enum');
    if UI.gif_mode
        Gif_KM(Dcm, enum, 'RigidReg')
    end
end

%%
%%%%%%%%%%%%%%% Create Trace %%%%%%%%%
if UI.trace_mode
    [Trace enum]= Trace_KM(Dcm, enum,1);
    [Trace_Norm]= Norm_KM(Trace, enum);  
    save([enum.dcm_dir '/Maps/Trace.mat'],'Trace','Trace_Norm','enum');  
    if UI.gif_mode
        Gif_KM(Trace, enum, 'Trace')
    end
end

%%
%%%%%%%%%%%%%%% Calculate ADC %%%%%%%%%
if UI.ADC_mode   
    [ADC]= ADC_KM(Trace, enum);
    save([enum.dcm_dir '/Maps/ADC.mat'],'ADC');
end

%%
%%%%%%%%%%%%%%% Create Mask %%%%%%%%%
if UI.mask_mode
    [Mask]= Mask_KM(Trace(:,:,:,2),30,60000);
    Mask(Mask>0)=1;
    %Dcm=Apply_Mask_KM(Dcm,Mask);    % Uncomment to apply the mask
    save([enum.dcm_dir '/Maps/Mask.mat'],'Mask','Dcm');  
end

%%
%%%%%%%%%%%%%%% Create Heart ROI %%%%%%%%%
if UI.roi_mode    
     [P_Endo,P_Epi,LV_Mask,Mask_Depth]= ROI_KM(Trace(:,:,:,2));
     [Mask_AHA] = ROI2AHA_KM (Dcm, P_Endo, P_Epi);
     %Dcm=Apply_Mask_KM(Dcm,LV_mask);  % Uncomment to apply the mask
     save([enum.dcm_dir '/Maps/ROI.mat'],'P_Endo','P_Epi','LV_Mask','Mask_AHA','Mask_Depth');
end

%%
%%%%%%%%%%%%%%% Calculate Tensor %%%%%%%%%
if UI.DTI_mode
    [Tensor,EigValue,EigVector,MD,FA,Trace_DTI] = Calc_Tensor_KM(Dcm, enum);
    save([enum.dcm_dir '/Maps/DTI.mat'],'Tensor','EigValue','EigVector','MD','FA','Trace_DTI');  
    
    % DTI2VTK_KM(EigVector, enum,1,'test'); % Uncomment to export fiber to
    % VTK
   
   %%%%%%%%%%%%%% Extract HA %%%%%%%%%%%%%
    if UI.roi_mode
        EigVect1=[];
        EigVect2=[];
        EigVect3=[];
        Elevation=[];
        EigVect1(:,:,1:size(Dcm,3),:)=squeeze(EigVector(:,:,:,1,:,1));
        EigVect2(:,:,1:size(Dcm,3),:)=squeeze(EigVector(:,:,:,1,:,2));
        EigVect3(:,:,1:size(Dcm,3),:)=squeeze(EigVector(:,:,:,1,:,3));
        Elevation(:,:,1:size(Dcm,3),:)=squeeze(EigVector(:,:,:,1,3,1));
        [HA TRA]= HA_KM( EigVect1, Dcm, P_Epi, P_Endo );
        [HA_filtered]= HA_Filter_KM(HA,LV_Mask ,Mask_Depth);
        save([enum.dcm_dir '/Maps/HA.mat'],'EigVect1','EigVect2','EigVect3','Elevation','HA','TRA','HA_filtered');  
    end
end


%%
% if UI.ADC_mode  && UI.trace_mode 
%     [Folder]= Recreate_Dicom_Maps_KM(ADC*1e6.*Mask,enum,[],'ADCMap',1015);
% 	Recreate_Dicom_Maps_KM(Trace*1e1.*Mask,enum,Folder,'TraceMap',1016);
% end

%%
warning on;
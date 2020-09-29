# -*- coding: utf-8 -*-
"""
Created on Wed Aug 14 13:17:31 2019

@author: ckohl
"""
from IPython import get_ipython
get_ipython().magic('reset -sf')
import mne
from surfer import Brain          
import numpy as np
from mayavi import mlab  
import matplotlib.pyplot as plt
#import os

# from mne import preprocessing
# mne.set_log_level('INFO')

# =============================================================================  
# =============================================================================
# INIT
# =============================================================================
# =============================================================================  

plot_steps_preproc=False
plot_steps_source=False
use_prep_coreg=True
skip_preproc=True
raw_dir='F:\\Phd\\Toby\\EEG'
shared_dir='C:\\Users\\ckohl\\Documents\\Virtual_Shared'
eeg_partic='03'
mri_partic='me'

# =============================================================================  
# =============================================================================
# PREPROCESS EEG
# =============================================================================
# =============================================================================  

# Load Raw EEG, Delete EMG, Load Montage
# =============================================================================
#os.chdir(raw_dir)
if skip_preproc==False:
    raw=mne.io.read_raw_brainvision(raw_dir+'\\'+eeg_partic+'.vhdr',eog=('left','right','top','bottom'),preload=True)
    raw.drop_channels(['top','bottom','left','right'])
    montage=mne.channels.read_montage('easycap-M10');
    channel_temp=montage.ch_names;
    channel_temp.remove('20');
    montage=mne.channels.read_montage('easycap-M10',ch_names=channel_temp,unit='auto',transform=False)
    #define fiducials # mne.io.read_fiducials(shared_dir+'\\fsaverage-fiducials.fif')
    montage.nasion=[ 5.20157830e-15, 9.49482203e+01, -2.96645722e+00] 
    montage.lpa=[-75.8658095 ,  13.37718913, -35.92255225]
    montage.rpa=[ 75.8658095 ,  13.37718913, -35.92255225]
    raw.set_montage(montage,set_dig=True)
    if plot_steps_preproc==True:
        montage.plot()
        raw.plot_sensors(show_names=True)

    # Delete Bad Channels
    # =============================================================================
    if plot_steps_preproc==True:
        raw.plot()
        raw.plot_psd(fmax=50)
    raw.info['bads']=['7','18']
    
    # Filter & Ref
    # =============================================================================
    raw.filter(1,40, fir_design='firwin')
    if plot_steps_preproc==True:
        raw.plot_psd(fmax=50)    
    # Avg Ref
    raw.set_eeg_reference('average', projection=True)
    
    # ICA
    # =============================================================================
    ica = mne.preprocessing.ICA( n_components=20, random_state=97, method='fastica')
    ica.fit(raw)
    if plot_steps_preproc==True:
        ica.plot_components() 
    ica.exclude=[0, 1 ,2]
    ica.apply(raw)
    
    # Interpolate
    raw.interpolate_bads()
    
    # Add Triggers
    # =============================================================================
    triggers = mne.read_annotations(raw_dir+'\\'+eeg_partic+'.vmrk')
    raw.set_annotations(triggers)
    events, event_ids = mne.events_from_annotations(raw)
    if plot_steps_preproc==True:
        mne.viz.plot_events(events)
        
    # Identify unimodal auditory (16 preceded by 1)
    for this_event in range(1,len(events)):
        if events[this_event][2]==16 and events[this_event-1][2]==1:
            events[this_event][2]=161
            
    # Epoch (& Reject)
    # =============================================================================
    reject_criteria=dict(eeg=50e-6) 
    epochs = mne.Epochs(raw, events, event_id=161, tmin=-0.1, tmax=0.5,baseline=(-0.1, 0),preload=True,reject=reject_criteria)
    if plot_steps_preproc==True:
        epochs.plot_image()
        epochs.plot_topo_image()
    erp=epochs.average()
    if plot_steps_preproc==True:
        erp.plot_topo()
        erp.plot(spatial_colors=True)
        erp.plot_joint(times=[0, 0.05, 0.1, 0.15, 0.125])
    
    #save
    #mne.Epochs.save(epochs, fname=shared_dir+'\\'+mri_partic+'-epo.fif')
else:
    epochs=mne.read_epochs(fname=shared_dir+'\\'+mri_partic+'-epo.fif',preload=True)
#ne.Evoked.save(erp,fname=shared_dir+'\\evoked-ave.fif')
#erp=mne.read_evokeds(shared_dir+'\\evoked-ave.fif')
# import pickle   
# pickle_out=open(shared_dir+'\\erp_file','wb')  
# pickle.dump(erp,pickle_out)
# pickle_out.close()
#pickle_in=open(shared_dir+'\\erp_file','rb')  
#erp=pickle.load(pickle_in)

# =============================================================================  
# =============================================================================  
# SOURCE LOCALISATION
# =============================================================================  
# =============================================================================  

            # =============================================================================    
            # =============================================================================
            # PROCESS MRI: EXTERNAL
            # =============================================================================
            # MRI needs to be processed in freesurfer and MNE-C
            # (which I do on VritualBox:MNE-C)
            # Shell Script 'mri_setup_pipe' (open with atom)  
            #   
            # 1: Surface Reconstruction: Freesurfer
            # 2: Source Space Setup: MNE-C
            # 3: BEM Mesh: MNE-C    
            # =============================================================================
            # =============================================================================

# Align EEG-MRI
# =============================================================================
if use_prep_coreg==False:    
    #info=mne.create_info(ch_names=montage.ch_names, sfreq=1,ch_types='eeg',montage=montage)
    #mne.viz.plot_alignment(info, subject=mri_partic,subjects_dir=shared_dir,eeg='original') 
    
    # This step opens gui to manually perform coregistration between MRI and EEG
    mne.gui.coregistration(inst=shared_dir+'\\evoked-ave.fif', subject=mri_partic, subjects_dir=shared_dir, trans=trans_file ) 
trans_file=shared_dir+'\\'+mri_partic+'-trans.fif'
mri_partic=mri_partic+'-trans' 
if plot_steps_source==True:
    #check coregistration
    info=mne.create_info(ch_names=montage.ch_names, sfreq=1,ch_types='eeg',montage=montage)
    mne.viz.plot_alignment(info, trans=trans_file,subject=mri_partic,subjects_dir=shared_dir)  

# Source Space (from MNE-C)
# =============================================================================
# the last step copied the subject folder we worked on into our Virtual_Shared directory  
# First, take sources made in MNE-C
# src=mne.read_source_spaces(shared_dir + '\\bem\\'+mri_partic+'-7-src.fif') # these are made in MNE-C, but I redo them cause I squished the head to align with EEG
compute_new_sourcespace=False
if compute_new_sourcespace==True:
    src=mne.setup_source_space(subject=mri_partic,subjects_dir=shared_dir)
    mne.SourceSpaces.save(src,shared_dir+'\\sourcespace-src.fif')
else:
    src=mne.read_source_spaces(fname=shared_dir+'\\sourcespace-src.fif') 
if plot_steps_source==True:
    mne.viz.plot_alignment(epochs.info, trans=trans_file, subject=mri_partic, src=src,subjects_dir=shared_dir, dig=True)
    #src.plot(head=False,brain=False, skull=False, subjects_dir=shared_dir,trans=trans_file)
    brain = Brain(hemi='rh', surf='orig', subjects_dir=shared_dir,subject_id=mri_partic)
    surf = brain.geo['rh']
    vertidx = np.where(src[1]['inuse'])[0]
    mlab.points3d(surf.x[vertidx], surf.y[vertidx],surf.z[vertidx], color=(1, 1, 0), scale_factor=1.5)
     
    rh =src[1]  # Visualize hemisphere
    verts = rh['rr']  # The vertices of the source space
    tris = rh['tris']  # Groups of three vertices that form triangles
    dip_pos = rh['rr'][rh['vertno']]  # The position of the dipoles
    red = (1.0, 0.0, 0.0)  
    # Plot the cortex
    mlab.triangular_mesh(verts[:, 0], verts[:, 1], verts[:, 2], tris,color=(0.5, 0.5, 0.5))
    # Show the dipoles as arrows pointing along the surface normal
    normals = rh['nn'][rh['vertno']]
    mlab.quiver3d(surf.x[rh['vertno']], surf.y[rh['vertno']],surf.z[rh['vertno']], normals[:, 0], normals[:, 1], normals[:, 2], color=(0.0, 0.0, 0.0),scale_factor=1.5)
 
 
# BEM
# =============================================================================
# triangulations of the interfaces between different tissues
compute_new_bem=False
if compute_new_bem==True:
    model=mne.make_bem_model(mri_partic,conductivity=(0.3, 0.006, 0.3), subjects_dir=shared_dir)   
    bem = mne.make_bem_solution(model)      
    mne.write_bem_solution(fname=shared_dir+'\\bem-bem',bem=bem)
else:
    mne.read_bem_solution(fname=shared_dir+'\\bem-bem')
if plot_steps_source==True:
    mne.viz.plot_bem(subject=mri_partic,subjects_dir=shared_dir, brain_surfaces='white', orientation='coronal') 
    
    

# Forward Model
# =============================================================================
# forward operator==gain matrix==leadfield matrix
compute_new_fwd=False
if compute_new_fwd==True:
    fwd = mne.make_forward_solution(raw.info, trans=trans_file, src=src, bem=bem, meg=False, eeg=True, mindist=5.0)    
    mne.write_forward_solution(shared_dir+'\\forward-fwd.fif',fwd,overwrite=True)
else:
    fwd=mne.read_forward_solution(shared_dir+'\\forward-fwd.fif')
    fwd= mne.convert_forward_solution(fwd, surf_ori=True) 
       

# Covariance
# =============================================================================         
cov = mne.compute_covariance(epochs, tmax=-0.1, method='shrunk')
if plot_steps_source==True:
    mne.viz.plot_cov(cov, epochs.info)

# Inverse Model
# =============================================================================
erp=epochs.average()    
inverse_operator=mne.minimum_norm.make_inverse_operator(info=erp.info,forward=fwd,noise_cov=cov,loose=.2, depth=.8)
#mne.minimum_norm.write_inverse_operator(shared_dir+ '\\invop-inv.fif',inverse_operator)
#inv=mne.minimum_norm.read_inverse_operator(shared_dir+ '\\invop-inv.fif')
method = "MNE"
snr = 3.
lambda2 = 1. / snr ** 2
stc=mne.minimum_norm.apply_inverse(evoked=erp,inverse_operator=inverse_operator, lambda2=lambda2, method=method,pick_ori='normal')
#stc.plot(initial_time=0.1, hemi='split', views=['lat', 'med'], subjects_dir=shared_dir,subject=mri_partic)
#stc = mne.read_source_estimate(shared_dir+'\\examplestc-rh.stc')

# Labels
# =============================================================================
#potential atlas: 'aparc', 'aparc.a2009s' (smallest), 'aparc.DKTatlas'
parc='aparc.a2009s'
labels = mne.read_labels_from_annot(subject=mri_partic,parc=parc,subjects_dir=shared_dir) ## DKTatlas40 or a2009s
if len(parc)>5 and parc[-2]=='9':
    label_oi='S_temporal_transverse-rh'
else:
    label_oi='transversetemporal-rh'
aud_label = [label for label in labels if label.name == label_oi][0]
if plot_steps_source==True:
    brain = Brain(subject_id=mri_partic,subjects_dir=shared_dir,surf='orig',hemi='rh', background='white', size=(800, 600))
    brain.add_annotation(parc)
    brain.add_label(aud_label, borders=False,color=[1, 0, 0])
    #plot label_oi & sources
    normals = src[1]['nn'][src[1]['vertno']]  
    brain = Brain(hemi='rh', surf='inflated', subjects_dir=shared_dir,subject_id=mri_partic)
    surf = brain.geo['rh']    
    mlab.quiver3d(surf.x[src[1]['vertno']], surf.y[src[1]['vertno']],surf.z[src[1]['vertno']], normals[:, 0], normals[:, 1], normals[:, 2], color=(0.0, 0.0, 0.0)  ,scale_factor=1.5)
    brain.add_label(aud_label, borders=False,color=[1, 0, 0])


mean_rh = stc.extract_label_time_course(aud_label, inverse_operator['src'], mode='mean')
plt.plot(stc.times,mean_rh.T)
a=1
mean_rh=mean_rh.T
np.savetxt(shared_dir+'\\mean_rh.txt',mean_rh,fmt='%s')
np.savetxt(shared_dir+'\\mean_rh_time.txt',stc.times,fmt='%s')

  








 brain = Brain(subject_id=mri_partic,subjects_dir=shared_dir,surf='orig',hemi='both', background='white', size=(800, 600))
    brain.add_annotation(parc)
 






brain = stc.plot(surface='inflated', hemi='lh', subjects_dir=shared_dir)
brain.set_data_time_index(300)  # 221 for S2
brain.scale_data_colormap(fmin=-1e-12, fmid=1e-12, fmax=50e-12, transparent=True)
brain.show_view('lateral')








vertno_max, time_max = stc.get_peak(hemi='rh')

surfer_kwargs = dict(
    subjects_dir=shared_dir,
    clim=dict(kind='value', lims=[8, 12, 15]), views='lateral',
    initial_time=time_max, time_unit='s', size=(800, 800), smoothing_steps=5)
brain = stc.plot(**surfer_kwargs)
brain.add_foci(vertno_max, coords_as_verts=True, hemi='rh', color='blue',
               scale_factor=0.6, alpha=0.5)
brain.add_text(0.1, 0.9, 'dSPM (plus location of maximal activation)', 'title',
               font_size=14)




stc_vec = mne.minimum_norm.apply_inverse(erp, inverse_operator, 
                        method='MNE', pick_ori='vector')
brain = stc_vec.plot(**surfer_kwargs)
brain.add_text(0.1, 0.9, 'Vector solution', 'title', font_size=20)





















    






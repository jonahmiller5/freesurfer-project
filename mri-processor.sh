#!/bin/bash
# The purpose of this program is to wait for an MRI to be sent by SFTP to this computer,
# wait for all 192 of the files to be accounted for, and then send it to another
# directory which converts MRIs to Freesurfer

# fswatch monitors “Shared” directory and pipes events to a while loop for interaction
fswatch -0 /Users/radiology/Downloads/Shared/ | while read -d "" event
    do
    
    # conditional makes sure event is a directory
    if [ -d $event ]
        then
        
        # conditional makes sure event isn’t an update to DS Storage 
        # only needed if monitored directory can be accessed in Finder, but never hurts
        if [ $event != *.DS_Store ]
            then
            
            # loop forces program to wait until all files in the MRI are successfully sent
            # necessary because SFTP sends files one by one instead of all at once
            while [ true ]
                do

                #count1 variable counts all non-hidden files in the event directory
                export count1=$(ls $event | wc -l)

                # conditional waits for all 192 files in the MRI to be sent then copies it to another directory
                # new directory is monitored for conversion to Freesurfer
                if [ $count1 = 192 ]
                    then
                    echo
                    echo FILE TRANSFER SUCCESSFUL - COPYING FILES NOW
                    echo
                    cp -r $event /Users/radiology/Workspace/Execute
                    rm -r $event
                    break
                fi
            done
        fi
    fi
done &


# This program waits for an MRI to be sent to the “Execute” directory, presumably from the SFTP monitoring program
# waits until all 192 files are accounted for, imports the subject into the subjects directory, then begins
# converting the MRI to Freesurfer. Once the conversion is complete, the program puts the aseg and aparc statistics
# into a table which can be accessed by the SFTP

# fswatch monitors “Execute” directory and pipes events to a while loop for interaction
fswatch -0 /Users/radiology/Workspace/Execute | while read -d "" event
    do

    # conditional makes sure event is a directory
    if [ -d $event ]
        then

        # conditional makes sure event isn’t an update to DS Storage 
        # only needed if monitored directory can be accessed in Finder, but never hurts
        if [ $event != “*.DS_Store” ]
            then

            # loop forces program to wait until all files in the MRI are successfully received
            # necessary in case cp sends files one by one instead of all at once
            while [ true ]
                do

                #count2 variable counts all non-hidden files in the event directory
                export count2=$(ls $event | wc -l)

                # conditional waits for all 192 files in the MRI to be received before continuing the program
                if [ $count2 = 192 ]
                    then
                    echo
                    echo FILES SUCCESSFULLY COPIED
                    echo
                    break
                fi
            done

##############################################################################################################################################################

            echo
            echo BEGINNING IMPORT PROCESS
            echo

            # loop checks each file in the MRI
            # if file doesn’t have an extension, it is assumed to be DICOM and .dcm is added to the end
            # files with extensions are ignored
            for file in $event/*
                do
                echo $file
                if [ ${file: -4} != “.*” ]
                    then
                    mv $file $file.dcm
                fi
            done
                    
            # finds one DICOM file and assigns it to a variable
            # only one is needed because “recon-all” command finds all other associated DICOM images
            export result=$(find $event -name *.dcm -print -quit) 

            # actual call to import MRI to subjects directory
            recon-all -i $result -s $event
                    
##############################################################################################################################################################

            echo
            echo BEGINNING CONVERSION PROCESS
            echo

            # call to convert the MRI to Freesurfer
            recon-all -s $event -all

##############################################################################################################################################################

            export subj=${event#/Users/radiology/Workspace/Execute/}
            
            echo
            echo BEGINNING DATA TABULATION
            echo
            
            # adds ASEG statistics to its own table in the SFTP    
            asegstats2table --subjects $subj --tablefile /Users/radiology/Workspace/Temps/temp1.txt
            sed 1d /Users/radiology/Workspace/Temps/temp1.txt >> /Users/radiology/Downloads/Shared/STATS_TABLES/aseg-stats.txt

            # adds APARC statistics for the right hemisphere to its own table in the SFTP
            aparcstats2table --subjects $subj --hemi rh --tablefile /Users/radiology/Workspace/Temps/temp2.txt
            sed 1d /Users/radiology/Workspace/Temps/temp2.txt >> /Users/radiology/Downloads/Shared/STATS_TABLES/aparc-stats-rh.txt
      
            # adds APARC statistics for the left hemisphere to its own table in the SFTP
            aparcstats2table --subjects $subj --hemi lh --tablefile /Users/radiology/Workspace/Temps/temp3.txt
            sed 1d /Users/radiology/Workspace/Temps/temp3.txt >> /Users/radiology/Downloads/Shared/STATS_TABLES/aparc-stats-lh.txt

##############################################################################################################################################################

            # once program has been executed completely, the MRI is removed from the “Execute” directory
            rm -r $event
        fi
    fi
done &
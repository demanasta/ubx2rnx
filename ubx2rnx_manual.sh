#!/usr/bin/env bash
VERSION="ubx2rnx - v0.1b1"

# //////////////////////////////////////////////////////////////////////////////
#HELP FUNCTION
function help {
  echo " Program Name : ubx2rnx.sh"
  echo " Version : ${VERSION}"
  echo " Purpose : convert ubx to rnx files"
  echo " Usage   : ubx2rnx.sh <config_file> [options] "
  echo " Switches: "
  echo ""
  exit 1
}

#BASH SETTINGS
set -e
set -o pipefail


# //////////////////////////////////////////////////////////////////////////////
# CHECK if necessary programs exist
# convbin, RNX2CRX/Z, gfzrnx

#Check for convbin
if ! [ -x "$(command -v convbin)" ]
then
    echo '[ERROR]: convbin is not installed'
    exit 1
fi

#Check RNX2CRX
if ! [ -x "$(command -v RNX2CRX)" ]
then
    echo '[ERROR]: RNX2CRX/Z is not installed'
    exit 1
fi

#Check RNX2CRZ
if ! [ -x "$(command -v RNX2CRZ)" ]
then
    echo '[ERROR]: RNX2CRZ is not installed'
    exit 1
fi

#Check compress
if ! [ -x "$(command -v compress)" ]
then
    echo '[ERROR]: RNX2CRX/Z is not installed'
    exit 1
fi

#Check gzip
if ! [ -x "$(command -v gzip)" ]
then
    echo '[ERROR]: RNX2CRX/Z is not installed'
    exit 1
fi

# Pre-defined variables
DAILY=0
HIGHRATE=1

# //////////////////////////////////////////////////////////////////////////////
#GET CML ARGUMENTS
if [ "$#" == 0 ]
then
  echo "[ERROR]: No input file"
  help
fi

while [ $# -gt 0  ]
do
    case "$1" in
        --config)
            conf_file=${2}
            # Check configuration file
            if [ ! -f ${conf_file} ]
            then
                echo "[ERROR]: config file ${conf_file} does not exis"
                exit 1
            else
                echo "...load configuration file ..."
                source ${conf_file}
            fi
            shift 2
            ;;
         -dinp)
             dateinp=${2}
             shift 2
             ;;
         -hinp)
             hourinp=${2}
             shift 2
             ;;
#        -finp)
#            inp_file=${2}
#            # Check input file for daily convert
#            if [ ! -f ${UBX_DIR}/${inp_file} ]
#            then
#                echo "[ERROR]: Input file ${inp_file} does not exist"
#                exit 1
#            else
#                echo "...load input file ..."
#            fi
#            shift 2
#            ;;
        --daily)
            DAILY=1
            HIGHRATE=0
            shift
            ;;
        --highrate)
            HIGHRATE=1
            DAILY=0
            shift
            ;;
#        --rate)
#            RATE=${2}
#            shift 2
#            ;;
        -h | --help)
            help
            ;;
        -v | --version)
            echo "version: ${VERSION}"
            exit 1
            shift
            ;;
#        *)
#            echo "[ERROR] Bad argument structure. argument \"${1}\" is not right"
#            echo "[STATUS] Script Finished Unsuccesfully! Exit Status 1"
#            exit 1
    esac
done






dateubx=$(date +%Y%m%d)

#UBXdirectory

#UBX_DIR=/media/DataInt/ProjectsNOA/21_lowcostGNSS/rnx_data/NOATL_Jul

#RNX_DIR=/media/DataInt/ProjectsNOA/21_lowcostGNSS/rnx_data/NOATL_Jul
#rnx_ver="3.04"
tr=(a b c d e f g h i j k l m n o p q r s t u v w x)

#cp ${UBX_DIR}/${ubx_file} ${RNX_DIR}/.

cd ${UBX_DIR}


# //////////////////////////////////////////////////////////////////////////////
## RATE 30-s create one RINEX file for previous day > Hatanaka > Compressed
if [ ${DAILY} -eq 1 ]
then
    year=$(date --date=${dateinp} +%Y)
    yy=$(date --date=${dateinp} +%y)
    doy=$(date --date=${dateinp} +%j)

    if [ ${RNX_VER} == "2.11" ]
    then
        #check if all hourly files exists
        for i in {14..23}
        do
          if test -f ${SITE_NAME}${doy}${tr[$i]}.${yy}d.Z
          then
              echo "pass"
          else
              echo "file ${SITE_NAME}${doy}${tr[$i]}.${yy}d.Z does not exist"
              exit 1
          fi
        done
        for i in `ls ${SITE_NAME}${doy}*.${yy}d.Z`
        do
            CRZ2RNX -f ${i}
        done
        # produce names for RINEX 2 format
        # xxxxdddh.yyo.Z
        rnxfile=${SITE_NAME}${doy}0.${yy}o
        crzfile=${SITE_NAME}${doy}0.${yy}d.Z

        # gfzrnx options
        # -epo_beg start from 00:00:00 not the day before
        # -d create rinex for hole day
        # -smp resample observations to 30-s rate
        # -crux header inforamtion file
        gfzrnx -finp ${SITE_NAME}${doy}{o..x}.${yy}o -fout ${rnxfile} \
            -kv -epo_beg ${year}${doy}_000000 -d 86370 -smp 30 \
            -crux ${HEADER_INFO} -f

        # convert to Hatanaka (d) and compressed (.Z) format
        RNX2CRZ -f ${rnxfile}

        # remove temporary files
        rm -rf  ${SITE_NAME}${doy}*.${yy}o

    elif [ ${RNX_VER} == "3.04" ]
    then
        #produce names for RINEX 3 format
        #check if all hourly files exists
        for i in {14..23}
        do
            if test -f ${SITE_NAME}${M}${R}${CCC}_${K}_${year}${doy}$(printf '%02d' $((i)))00_01H_01S_${tt}.crx.gz
          then
              echo "pass"
          else
              echo "file ${SITE_NAME}${M}${R}${CCC}_${K}_${year}${doy}$(printf '%02d' $((i)))00_01H_01S_${tt}.crx.gz does not exist"
              exit 1
          fi
        done

        for i in `ls ${SITE_NAME}${M}${R}${CCC}_${K}_${year}${doy}*00_01H_01S_${tt}.crx.gz`
        do
            gzip -d -f ${i}
            CRX2RNX -f ${i:0:38}
        done
        # XXXXMRCCC_K_YYYYDDDHHMM_01D_30S_tt.FFF.gz
        # check configuration file for details
        fname=${SITE_NAME}${M}${R}${CCC}_${K}_${year}${doy}0000_01D_30S_${tt}
        rnxfile=${fname}.rnx
        crxfile=${fname}.crx
        crzfile=${fname}.crx.gz

        gfzrnx -finp ${SITE_NAME}${M}${R}${CCC}_${K}_${year}${doy}{14..23}00_01H_01S_${tt}.rnx -fout ${rnxfile} \
            -kv -epo_beg ${year}${doy}_000000 -d 86370 -smp 30 \
            -crux ${HEADER_INFO} -f

        # Convert to Hatanaka format
        RNX2CRX -f ${rnxfile}

        # Compress with gzip
        gzip -f -c ${crxfile} > ${crzfile}

        # remove temporary files
        rm -rf  ${SITE_NAME}${doy}*.${yy}o ${SITE_NAME}${doy}*.obs
        rm -rf ${rnxfile} ${crxfile}
    else
        echo "use rinex 2.11 or 3.04 > config file"
        exit 1
    fi
    # TO DO: push files to final ftp potision
    # 30-s YYYY/DDD/YYt/

    if test -d ${RNX_DAILY}/${year}
    then
        if test -d ${RNX_DAILY}/${year}/${doy}
        then
            if test -d ${RNX_DAILY}/${year}/${doy}/${yy}d
            then
                echo "directory exists"
            else
                mkdir ${RNX_DAILY}/${year}/${doy}/${yy}d
            fi
        else
            mkdir ${RNX_DAILY}/${year}/${doy}
            mkdir ${RNX_DAILY}/${year}/${doy}/${yy}d
        fi
    else
        mkdir ${RNX_DAILY}/${year}
        mkdir ${RNX_DAILY}/${year}/${doy}
        mkdir ${RNX_DAILY}/${year}/${doy}/${yy}d
    fi

    cp ${crzfile} ${RNX_DAILY}/${year}/${doy}/${yy}d/.

elif [ ${HIGHRATE} -eq  1 ]
then
    ubx_file=$(date --date=${dateinp} +%Y-%m-%d)_${hourinp}-00-00_GNSS-1.ubx

    #check if file exist
    if test -f ${UBX_DIR}/${ubx_file}
    then
        rnx_date=${ubx_file:0:10}
        rnx_hour=${ubx_file:11:2}
        year=$(date -d ${rnx_date} +%Y)
        yy=$(date -d ${rnx_date} +%y)
        doy=$(date -d ${rnx_date} +%j)

        ax_hour=${tr[${rnx_hour#0}]}

        fout_name=${SITE_NAME}${doy}${ax_hour}

        obshfile=${fout_name}.obs

        # convert grom ubx > rinex fromat
        # rinex version ${RNX_VER} from config file
        convbin ${ubx_file} -v ${RNX_VER} -o ${obshfile}

        # use gfzrnx to check obs file from config contain errors
        #gfzrnx -finp ${obshfile} -fout ${rnxhfile} -f -kv
        #wait

        if [ ${RNX_VER} == "2.11" ]
        then
            # produce names for RINEX 2 format
            # xxxxdddh.yyo.Z
            rnxhfile=${SITE_NAME}${doy}${ax_hour}.${yy}o
            crzhfile=${SITE_NAME}${doy}${ax_hour}.${yy}d.Z

            # gfzrnx options
            # -epo_beg start from 00:00:00 not the day before
            # -d create rinex for hole day
            # -smp resample observations to 30-s rate
            # -crux header inforamtion file
            gfzrnx -finp ${obshfile} -fout ${rnxhfile} \
                -kv \
                -crux ${HEADER_INFO} -f

            wait

            # convert to Hatanaka (d) and compressed (.Z) format
            RNX2CRZ -f ${rnxhfile}

            # remove temporary files
            rm -rf  ${SITE_NAME}${doy}*.${yy}o ${SITE_NAME}${doy}*.obs

        elif [ ${RNX_VER} == "3.04" ]
        then
            #produce names for RINEX 3 format
            # XXXXMRCCC_K_YYYYDDDHHMM_01D_30S_tt.FFF.gz
            # check configuration file for details
            fname=${SITE_NAME}${M}${R}${CCC}_${K}_${year}${doy}${rnx_hour}00_01H_01S_${tt}
            rnxhfile=${fname}.rnx
            crxhfile=${fname}.crx
            crzhfile=${fname}.crx.gz

            gfzrnx -finp ${obshfile} -fout ${rnxhfile} \
                -kv \
                -crux ${HEADER_INFO} -f

            wait

            # Convert to Hatanaka format
            RNX2CRX -f ${rnxhfile}

            # Compress with gzip
            gzip -f -c ${crxhfile} > ${crzhfile}

            # remove temporary files
            rm -rf  ${SITE_NAME}${doy}*.${yy}o ${SITE_NAME}${doy}*.obs
            rm -rf ${rnxhfile} ${crxhfile}
        else
            echo "use rinex 2.11 or 3.04 > config file"
            exit 1
        fi
        #YYYY/DDD/YYt/HH/mmmmDDDHMM.YYt.Z
        if test -d ${RNX_HIGH}/${year}
        then
            if test -d ${RNX_HIGH}/${year}/${doy}
            then
                if test -d ${RNX_HIGH}/${year}/${doy}/${yy}d
                then
                    if test -d ${RNX_HIGH}/${year}/${doy}/${yy}d/${rnx_hour}
                    then
                        echo "directory exists"
                    else
                        mkdir ${RNX_HIGH}/${year}/${doy}/${yy}d/${rnx_hour}
                    fi
                else
                    mkdir ${RNX_HIGH}/${year}/${doy}/${yy}d
                    mkdir ${RNX_HIGH}/${year}/${doy}/${yy}d/${rnx_hour}
                fi
            else
                mkdir ${RNX_HIGH}/${year}/${doy}
                mkdir ${RNX_HIGH}/${year}/${doy}/${yy}d
                mkdir ${RNX_HIGH}/${year}/${doy}/${yy}d/${rnx_hour}
            fi
        else
            mkdir ${RNX_HIGH}/${year}
            mkdir ${RNX_HIGH}/${year}/${doy}
            mkdir ${RNX_HIGH}/${year}/${doy}/${yy}d
            mkdir ${RNX_HIGH}/${year}/${doy}/${yy}d/${rnx_hour}
        fi

        cp ${crzhfile} ${RNX_HIGH}/${year}/${doy}/${yy}d/${rnx_hour}/.
    else
        echo "file ${UBX_DIR}/${ubx_file} does not exist"
        exit 1
    fi

else
    echo "choose RATE 30-s or 1Hz"
    exit 1
fi





exit 0

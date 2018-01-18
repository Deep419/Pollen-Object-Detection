#! /bin/bash
# exec 1>$PBS_O_WORKDIR/out 2>$PBS_O_WORKDIR/err
#
# ===== PBS OPTIONS =====
#
#PBS -N "parallel_patch_creator"
#PBS -q titan
#PBS -l walltime=400:00:00
#PBS -l nodes=1:ppn=8
#PBS -V
#
# ===== END PBS OPTIONS =====
#
# ==== Main ======
cd $PBS_O_WORKDIR
mkdir log
{
module load matlab/R2017a
matlab -nodisplay -nosplash -nodesktop -r "patch_create; exit;"
} > log/output_"$PBS_JOBNAME"_$PBS_JOBID 2>log/errorLog_"$PBS_JOBNAME"_$PBS_JOBID

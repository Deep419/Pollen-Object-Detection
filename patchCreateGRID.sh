#! /bin/bash
# exec 1>$PBS_O_WORKDIR/out 2>$PBS_O_WORKDIR/err
#
# ===== PBS OPTIONS =====
#
#PBS -N "parPatchGenerate"
#PBS -q copperhead
#PBS -l walltime=8:00:00
#PBS -l nodes=1:ppn=32
#PBS -l mem=32GB
#PBS -V
#
# ===== END PBS OPTIONS =====
#
# ==== Main ======
cd $PBS_O_WORKDIR
mkdir log
{
module load matlab/R2018a
matlab -nodisplay -nosplash -nodesktop -r "patch_create('GRID'); exit;"
} > log/output_"$PBS_JOBNAME"_$PBS_JOBID 2>log/errorLog_"$PBS_JOBNAME"_$PBS_JOBID
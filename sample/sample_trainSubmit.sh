#! /bin/bash
# exec 1>$PBS_O_WORKDIR/out 2>$PBS_O_WORKDIR/err
#
# ===== PBS OPTIONS =====
#
#PBS -N "jobName"
#PBS -q titan
#PBS -l walltime=600:00:00
#PBS -l nodes=1:ppn=1:gpus=1,mem=16GB
#PBS -V
#
# ===== END PBS OPTIONS =====
#
# ==== Main ======
cd $PBS_O_WORKDIR
mkdir log
{
module load matlab/R2017b
matlab -nodisplay -nosplash -nodesktop -r "sample_training; exit;"
} > log/output_"$PBS_JOBNAME"_$PBS_JOBID 2>log/errorLog_"$PBS_JOBNAME"_$PBS_JOBID

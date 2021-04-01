#!/bin/bash

DATASETS=$1

LOG=qsub_exec.log
#$ -cwd
#$ -o qsub_exec.log
#$ -l q_node=1
#$ -l h_rt=24:00:00
#$ -N river-mapping
#$ -j y
#$ -m abe
#$ -M heromiya@hotmail.com

. /etc/profile.d/modules.sh
module load intel/19.0.0.117 cuda/10.1.105 nccl/2.4.2 cudnn/7.6
#tensorflow/1.12.0
#module load intel cuda/9.0.176 nccl/2.2.13 cudnn/7.1 tensorflow/1.9.0
#. /home/7/17IA0902/anaconda3/etc/profile.d/conda.sh

export PATH=$PATH:/home/7/17IA0902/miniconda3/bin
export LD_LIBRARY_PATH=/home/7/17IA0902/miniconda3/lib:/home/7/17IA0902/miniconda3/lib64:/apps/t3/sles12sp2/cuda/10.1.105/lib64:/apps/t3/sles12sp2/free/cudnn/7.6/cuda/10.1/lib64:$LD_LIBRARY_PATH 
#/home/7/17IA0902/miniconda3/bin/python train.py 'weights.2021-02-15 09:46:17.283580.0011-0.2907.FPN.efficientnetb2.hdf5'
export CUDA_VISIBLE_DEVICES=0
/home/7/17IA0902/miniconda3/bin/python predict_auto.py -data $DATASETS -checkpoints FPN_epoch_400_Mar01_14_21.pth -batch_size 22 -georef true

#/home/7/17IA0902/apps/bin/python3 apply_mapping.py "weights.2020-04-28 02:42:45.865541.0515-0.3070.single_gpu.hdf5" test_img test_results 4096

#/apps/t3/sles12sp2/free/cudnn/7.6/cuda/10.1/lib64 /apps/t3/sles12sp2/cuda/11.0/lib64: :/home/7/17IA0902/apps/cuda-11/lib64

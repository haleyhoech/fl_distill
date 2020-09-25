#!/bin/bash
#SBATCH --mail-type=ALL
#SBATCH --mail-user=haley.hoech@hhi.fraunhofer.de
#SBATCH --output=out/%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gpus=1


cmdargs=$1

hyperparameters=' [{
	"dataset" : ["cifar10"], 
	"distill_dataset" : ["stl10"],
	"net" : ["lenet_cifar"],
	

	"n_clients" : [20],
	"classes_per_client" : [100.0, 10.0, 10.0, 0.1, 0.01],
	"balancedness" : [1.0],


	"communication_rounds" : [10],
	"participation_rate" : [0.4],
	"local_epochs" : [20],
	"distill_epochs" : [10],
	"n_distill" : [100000], 

	
	"batch_size" : [128],
	"aggregation_mode" : ["FD"],
	"distill_mode" : ["regular", "outlier_score"],
	"only_linear" : [false],
	
	"lr" : [0.1, 0.01, 0.001],

	"pretrained" : [null, {"stl10" : "simclr_net_bn_stl10_80epochs.pth"}],

	"save_model" : [null],
	"log_frequency" : [-100],
	"log_path" : ["outlier_score_cifar_simclrnet_bn/"],
	"job_id" : [['$SLURM_JOB_ID']]}]'



if [[ "$HOSTNAME" == *"vca"* ]]; then # Cluster

	RESULTS_PATH="/opt/small_files/"
	DATA_PATH="/opt/in_ram_data/"
	CHECKPOINT_PATH="/opt/checkpoints/"

	echo $hyperparameters
	source "/etc/slurm/local_job_dir.sh"

	export SINGULARITY_BINDPATH="$LOCAL_DATA:/data,$LOCAL_JOB_DIR:/mnt/output,./code:/opt/code,./checkpoints:/opt/checkpoints,./results:/opt/small_files,$HOME/in_ram_data:/opt/in_ram_data"
	singularity exec --nv $HOME/base_images/pytorch15.sif python -u /opt/code/federated_learning.py --hp="$hyperparameters" --RESULTS_PATH="$RESULTS_PATH" --DATA_PATH="$DATA_PATH" --CHECKPOINT_PATH="$CHECKPOINT_PATH" $cmdargs

	mkdir -p results
	cp -r ${LOCAL_JOB_DIR}/. ${SLURM_SUBMIT_DIR}/results	


else # Local

	RESULTS_PATH="results/"
	DATA_PATH="~/Data/PyTorch/"
	CHECKPOINT_PATH="checkpoints/"

	python -u code/federated_learning.py --hp="$hyperparameters" --RESULTS_PATH="$RESULTS_PATH" --DATA_PATH="$DATA_PATH" --CHECKPOINT_PATH="$CHECKPOINT_PATH" $cmdargs




fi







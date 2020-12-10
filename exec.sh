#!/bin/bash
#SBATCH --mail-type=ALL
#SBATCH --mail-user=haley.hoech@hhi.fraunhofer.de
#SBATCH --output=out/%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gpus=1


cmdargs=$1

hpo=true

hyperparameters=' [{
	"dataset" : ["cifar10"],
	"distill_dataset" : ["stl10"],
	"net" : ["lenet_cifar"],

	"n_clients" : [20],
	"classes_per_client" : [0.1],
	"balancedness" : [1.0],

	"communication_rounds" : [10],
	"participation_rate" : [0.4],
	"local_epochs" : [20],
	"distill_epochs" : [10],
	"n_distill" : [100000],

	"batch_size" : [128],
	"aggregation_mode" : ["FD"],
	"distill_mode" : ["pate"],
	"only_linear" : [false],
	"lr" : [0.1],

	"pretrained" : ["simclr_resnet8_stl10_100epochs.pth"],

	"save_model" : [null],
	"log_frequency" : [-100],
	"log_path" : ["test/"],
	"job_id" : [['$SLURM_JOB_ID']]}]'


if [[ $hpo == true ]]; then

	run_command="hpo.py"

else

	run_command="federated_learning.py"

fi




if [[ "$HOSTNAME" == *"vca"* ]]; then # Cluster

	RESULTS_PATH="/opt/small_files/"
	DATA_PATH="/opt/in_ram_data/"
	CHECKPOINT_PATH="/opt/checkpoints/"
	CODE_SRC="/opt/code/"
	SHARE_SRC="/opt/share/"

	echo $hyperparameters
	source "/etc/slurm/local_job_dir.sh"

	export SINGULARITY_BINDPATH="$LOCAL_DATA:/data,$LOCAL_JOB_DIR:/mnt/output,./code:/opt/code,./checkpoints:/opt/checkpoints,./results:/opt/small_files,$HOME/in_ram_data:/opt/in_ram_data,./share:/opt/share"
	singularity exec --nv $HOME/base_images/pytorch15.sif python -u "$CODE_SRC${run_command}" --hp="$hyperparameters" --RESULTS_PATH="$RESULTS_PATH" --DATA_PATH="$DATA_PATH" --CHECKPOINT_PATH="$CHECKPOINT_PATH" --SHARE_PATH="$SHARE_SRC" --WORKERS 16 $cmdargs

	mkdir -p results
	cp -r ${LOCAL_JOB_DIR}/. ${SLURM_SUBMIT_DIR}/results	


else # Local

	RESULTS_PATH="results/"
	DATA_PATH="~/Data/PyTorch/"
	CHECKPOINT_PATH="checkpoints/"
	CODE_SRC="code/"
	SHARE_SRC="share/"

	python -u "$CODE_SRC${run_command}" --hp="$hyperparameters" --RESULTS_PATH="$RESULTS_PATH" --DATA_PATH="$DATA_PATH" --CHECKPOINT_PATH="$CHECKPOINT_PATH" --SHARE_PATH="$SHARE_SRC" --WORKERS 6 $cmdargs

fi

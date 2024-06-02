#!/bin/sh

jdir=/user/work/shared_analytics/sub_scripts
keywords=( ensembles rscript python coral conda UMRUN fireworks )

noModJD=noModuleJobscripts.log
checkModJD=checkModJD.log
cp $noModJD $checkModJD
matchSWJD=matchSWJD.log


for k in "${keywords[@]}"; do

#for f in `cat $checkModJD`; do
for f in `ls $jdir/slurm-127357*.sh | awk -F'/' '{print $NF}'`; do 

	unset j
	j=$(grep -l -c $k $jdir/$f | sed -e 's/.*-\([0-9]*\)\..*/\1/g')
	
	if [ ! -z ${j} ]; then 
		echo $j | awk '{print "bc4|"$1"|manual/'$k'"}' >> $matchSWJD 
#		time sed -i -e "/$j/d" $checkModJD
	fi


done

done

###########################################
## Push all job scripts into a single file

## first pass
allJS=allJS.log
rm $allJS
for f in `cat $noModJD`; do
#for f in $(ls $jdir/slurm-127357*.sh | awk -F'/' '{print $NF}'); do

	j=$(echo $f | sed -e 's/.*-\([0-9]*\)\..*/\1/g')

	cat $jdir/$f | grep -v "^#" | sed '/^[[:space:]]*$/d' | sed -e 's/^/'$j:'/g' >> $allJS
done
cp allJS.log allJS.log~1


## 
unset keywords
declare -A keywords
keywords[d2q9-bgk]="LatticeBoltzmannSolver"
keywords[ensembles]="UM"
keywords[Rscript]="R"
keywords[python]="python"
keywords[coral]="coral"
keywords[conda]="conda"
keywords[UMRUN]="UM"
keywords[fireworks]="fireworks"
keywords[snakemake]="snakemake"
keywords[umui_runs]="UM"
keywords[MSMC2]="MSMC2"

outCSV=manual_jobscript_sw_analysis_bc4_01-06-2024-1.csv
headers="Cluster,JobID,Module"
echo $headers > $outCSV

for k in "${!keywords[@]}"; do
	grep -i $k $allJS | awk -F':' '{print $1}' | sort -n | uniq | \
	sed -e 's/^/bc4,/g' -e 's/$/,manual\/'${keywords[$k]}'/g'
done | sort -d | uniq >> $outCSV

#### second pass
# copy files across to powerbi-data area

cat slurm_jobscripts.log | sed -e 's/.*-\([0-9]*\)\..*/\1/g' > slurm_jobIds.log
cat noModuleJobscripts.log | sed -e 's/.*-\([0-9]*\)\..*/\1/g' > slurm_noMod_jobIds.log

cd powerbi-data
cp /user/work/shared_analytics/module_analysis/30-04-2024.txt bp_30-04-2024.txt
cat * | grep -v "JobID,Module" | sed 's/^bc4,//g' | awk -F',' '{print $1}' | sort -n | uniq > identifiedJobIDs.log
cat * | grep -v "JobID,Module" | sed 's/^bp,//g' | awk -F',' '{print $1}' | sort -n | uniq > identifiedJobIDs.log
cd ..


cat slurm_jobIds.log powerbi-data/identifiedJobIDs.log | sort -n | uniq -c | awk '{if ($1 == 1) print $2}' > missingJobIds.log

allJS="allJS.log~2"
#rm $allJS
cat missingJobIds.log | xargs -I{} sh -c "cat $jdir/*{}.sh | grep -v '^#' | sed '/^[[:space:]]*$/d' | egrep -v 'module purge|mkdir |cd |rm |cp |echo |export |OMP_NUM_THREADS|pwd|.bashrc' | sed 's/^/{}: /g'" >> $allJS

# to pick up from last entry use:
cat missingJobIds.log | sed '0,/^7399612$/d'

# checking status
cat allJS.log~2 | awk -F':' '{print $1}' | sort -n | uniq | wc -l && cat missingJobIds.log  | wc -l

# screening the output
cat allJS.log~2 | awk -F':' '{print $2}' | sort -d | uniq -c | awk '{if ($1 > 1) print $0}' | sort -n | egrep -v "sleep|wait|fi|done|RENVCMD|07b-run_cis_vmeQTL.sh|sbatch sub.sh|module list|ulimit|jupyter notebook|SCRATCH_|R CMD BATCH|THREADS=|cat |chmod |for |sed |java|conda|source |printf|if |which |wc -l|else|mv |iqtree2|python|jobName|abaqus|OUTDIR|.jar|grep |cut |unset|runtime|end.time|start.time|\$dt|WORKDIR|PWD|pwd|sbatch|sander|salmon|exit|DLMONTE|gzip|molsurf|autoimage|regenie|parent_fpath=|input_folder=|STAR|Rosetta_|case |esac|SBATCH |rsync|awk |job_name=|endmsg|iqtree|ls -l" | tac | more > allJS.log~2.cleaned

cat allJS.log~2.cleaned | grep module  | egrep -v "reset|init|unload" | sed -e 's/.*load //g' -e 's/.*add //g' -e 's/.*restore //g' -e 's/.*module //g' -e 's/# BluePebble//g' | xargs -n1 | sed -e 's/ $/g/' -e 's/^ //g' -e 's/^apps\///g' -e 's/^lang\///g' -e 's/^lib\///g' -e 's/^tools\///g' -e 's/^system\///g' |  sed -e 's/\/.*//g' | sort -d | uniq | tr 'A-Z' 'a-z' | awk '{print "keywords["$1"]=\""$1"\""}'



unset keywords
declare -A keywords
keywords[abaqus]="abaqus"
keywords[amber]="amber"
keywords[angsd]="angsd"
keywords[astral]="astral"
keywords[bcftools]="bcftools"
keywords[blast]="blast"
keywords[blastp]="blastp"
keywords[BOLT-LMM]="bolt-lmm"
keywords[boost]="boost"
keywords[bowtie2]="bowtie2"
keywords[bwa]="bwa"
keywords[cdo]="cdo"
keywords[cmake]="cmake"
keywords[conda]="conda"
keywords[coral]="coral"
keywords[cpptraj]="amber"
keywords[cuda]="cuda"
keywords[cudnn]="cudnn"
keywords[d2q9-bgk]="LatticeBoltzmannSolver"
keywords[DECIPHeR]="DECIPHeR"
keywords[diamond]="diamond"
keywords[diffeqtorch]="diffeqtorch"
keywords[DLMONTE]="dl-monte"
keywords[DYNAEXE]="ls-dyna"
keywords[engine_par]="visit"
keywords[ensembles]="UM"
keywords[fastp]="fastp"
keywords[fastqc]="fastqc"
keywords[ffmpeg]="ffmpeg"
keywords[fftw]="fftw"
keywords[fireworks]="fireworks"
keywords[gatk]="gatk"
keywords[gaussian]="gaussian"
keywords[gcc]="gcc"
keywords[geant]="geant"
keywords[git]="git"
keywords[gmx_mpi]="gromacs"
keywords[go]="go"
keywords[gromacs]="gromacs"
keywords[hdf5]="hdf5"
keywords[hmmer]="hmmer"
keywords[htslib]="htslib"
keywords[icu]="icu"
keywords[ifort]="ifort"
keywords[intel-parallel-studio-xe]="intel-parallel-studio-xe"
keywords[iqtree2]="iqtree2"
keywords[jags]="jags"
keywords[java]="java"
keywords[julia]="julia"
keywords[jupyter]="jupyter"
keywords[lammps]="lammps"
keywords[languages]="languages"
keywords[ldsc]="ldsc"
keywords[ls-dyna]="ls-dyna"
keywords[lumerical]="lumerical"
keywords[mafft]="mafft"
keywords[matlab]="matlab"
keywords[mcmctree]="paml"
keywords[miniprot]="miniprot"
keywords[molpro]="molpro"
keywords[molsurf]="amber"
keywords[mrbayes]="mrbayes"
keywords[MSMC2]="msmc2"
keywords[nastran]="nastran"
keywords[n_body3D]="n_body3d"
keywords[nco-toolkit]="nco-toolkit"
keywords[netlogo]="netlogo"
keywords[nextflow]="nextflow"
keywords[openmpi]="openmpi"
keywords[opensees]="opensees"
keywords[orca]="orca"
keywords[paml]="paml"
keywords[parmetis]="parmetis"
keywords[phylobayes]="phylobayes"
keywords[picard]="picard"
keywords[plink]="plink"
keywords[powerflow]="powerflow"
keywords[prequal]="prequal"
keywords[python]="python"
keywords[pytorch]="pytorch"
keywords['R CMD BATCH']="r"
keywords[regenie]="regenie"
keywords[RENVCMD]="r"
keywords[root]="root"
keywords[Rosetta]="rosetta"
keywords[languages.r]="r"
keywords[Rscript]="r"
keywords[salmon]="salmon"
keywords[samtools]="samtools"
keywords[sander]="amber"
keywords[schrodinger]="schrodinger"
keywords[singleshot]="fireworks"
keywords[singularity]="singularity"
keywords[snakemake]="snakemake"
keywords[spades]="spades"
keywords[sratoolkit]="sratoolkit"
keywords[star]="star"
keywords[swift_basic]="swift"
keywords[swift_intel2020_basic]="swift"
keywords[texlive]="texlive"
keywords[tflow]="tensorflow"
keywords[trimai]="trimai"
keywords[trimal]="trimal"
keywords[trimmomatic]="trimmomatic"
keywords[turbomole]="turbomole"
keywords[UMRUN]="UM"
keywords[umui_runs]="UM"
keywords[wrf]="wrf"
keywords[xerces]="xerces"
keywords[yq_linux_386]="yq"


outCSV=manual_jobscript_sw_analysis_bc4_01-06-2024-2.csv
headers="Cluster,JobID,Module"
echo $headers > $outCSV
allJS="allJS.log~2"

for k in "${!keywords[@]}"; do
        grep -i "$k" $allJS | awk -F':' '{print $1}' | sort -n | uniq | \
        sed -e 's/^/bc4,/g' -e 's/$/,manual\/'${keywords[$k]}'/g'
done | sort -d | uniq >> $outCSV



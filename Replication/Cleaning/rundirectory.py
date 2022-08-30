import subprocess
import os 
import re 
import sys

def run_stata(script, input_folder="", output_folder=""):
	'''
	Run stata dofile in batch mode, deletes the log file and fix the working directory
	Function adapted from: https://hofmanpaul.com/automation/rundirectory-py/
	'''
	print(f"\n\n\n\nRunning {script}")

	# Delimate folders with quotes (in case there are spaces)
	input_folder = '"' + input_folder + '"'
	output_folder = '"' + output_folder + '"'

	if sys.platform == "win32":
		subprocess.call([stata_path_win, "-e", "do", script, input_folder, output_folder])
	else:
		subprocess.call([stata_path_mac, "-b", "do", script, input_folder, output_folder])

	# Print STATA log output and shut down if an error is encountered
	err=re.compile("^r\([0-9]+\);$")
	lastline = ""
	with open("{}.log".format(script[0:-3]), 'r') as logfile:
		for line in logfile:
			print(line)
			if err.match(line):
				print("Error:")
				print(lastline)
				print(line)
				sys.exit("Stata Error code {line} in {fileloc}".format(line=line[0:-2], fileloc=script) )
				lastline=line

	os.remove("{}.log".format(script[0:-3]))

def run_python(script, *args):
	cmd = ["python3", script]
	for arg in args:
		if len(arg.split()) == 1:
			cmd.append(arg)
		else:
			cmd.append('"' + arg + '"')
	print(f"\n\n\n\nRunning {' '.join(cmd)}")
	subprocess.call(cmd)

#####################################################################
# RUN ALL CLEANING PROGRAMS IN ORDER
#####################################################################
if __name__ == "__main__":
	# Redirect to cleaning ddirectory, if we are not there yet
	cleaning_directory = "/Users/vbp/Dropbox (Personal)/Mac/Documents/Princeton/wealth-housing/Replication/Cleaning"
	analysis_directory = "/Users/vbp/Dropbox (Personal)/Mac/Documents/Princeton/wealth-housing/Replication/Analysis"
	os.chdir(cleaning_directory)

	# Set stata location
	stata_path_mac = "/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp"
	stata_path_win = "C:/Program Files (x86)/Stata13/StataMP-64.exe"

	# Set folders
	main_dir = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning"
	
	# Input (raw) data
	input_folder = os.path.join(main_dir, "Input")
	housing_data_folder = os.path.join(input_folder, "gov_uk")
	interest_rate_data_folder = os.path.join(input_folder, "interest_rates")

	# Working data
	working_folder = os.path.join(main_dir, "Working")
	python_working_folder = os.path.join(working_folder, "python_working")
	stata_working_folder = os.path.join(working_folder, "stata_working")

	# Output (cleaned) data
	output_folder = os.path.join(main_dir, "Output")


	print("Wait for the message 'DONE' to show up. The Stata dofile run in the background so it might seem like the program is finished when it isn't")


	# run_stata("1_set_presets.do", input_folder=input_folder, output_folder=output_folder)
	# run_stata("2_clean_lease.do", input_folder=housing_data_folder, output_folder=stata_working_folder)
	# run_stata("3_clean_price.do", input_folder=housing_data_folder, output_folder=stata_working_folder)
	# run_stata("4_clean_interest_rates.do", input_folder=interest_rate_data_folder, output_folder=stata_working_folder)
	# run_stata("5_merge_on_merge_keys.do", input_folder=stata_working_folder)
	# run_python("extract_unmerged_data.py", "postcode", stata_working_folder, python_working_folder)
	# run_python("link_unmerged_data.py", "postcode", stata_working_folder, python_working_folder)
	# run_stata("6_merge_python_results_postcodes.do", input_folder=stata_working_folder)
	# run_python("extract_unmerged_data.py", "city", stata_working_folder, python_working_folder)
	# run_python("link_unmerged_data.py", "city", stata_working_folder, python_working_folder)
	# run_stata("7_merge_python_results_no_postcodes.do", input_folder=stata_working_folder)
	# run_stata("8_merge_all_data.do", input_folder=stata_working_folder)
	run_stata("9_finalize_data.do", input_folder=stata_working_folder, output_folder=output_folder)

	os.chdir(analysis_directory)
	run_stata("rundirectory.do")
	# run_stata("lease_extensions.do")
	# run_stata("more_lease_variation.do")

	print("DONE")

import subprocess
import os 
import re 
import sys
import pandas as pd

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

def convert_encoding(bad_text):
	ret_txt = ''
	for item in str(bad_text):
		item = item
		ret_txt += item if len(item.encode(encoding='utf_8')) == 1 else ''
	return ret_txt

def append_files(folder_path, file_name, working_folder):

	all_filenames = [os.path.join(folder_path, folder, file_name) for folder in os.listdir(folder_path) if os.path.isdir(os.path.join(folder_path, folder))]
	combined_csv = pd.concat([pd.read_csv(f) for f in all_filenames ])
	combined_csv[['ADDRESS1', 'ADDRESS2', 'ADDRESS3', 'POSTCODE']] = combined_csv[['ADDRESS1', 'ADDRESS2', 'ADDRESS3', 'POSTCODE']].fillna('')
	combined_csv = combined_csv.astype(str)
	combined_csv["description"] = combined_csv["ADDRESS1"] + " " + combined_csv["ADDRESS2"] + " " + combined_csv["ADDRESS3"] + " " + combined_csv["POSTCODE"]
	combined_csv.to_csv(os.path.join(working_folder, "combined_characteristic_files.csv"), index=False, encoding='utf-8-sig')
	# print("Output to stata:")
	# combined_csv.to_stata(os.path.join(working_folder, "combined_characteristic_files.dta"), version=118)


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
	hedonic_data_folder = os.path.join(input_folder, "characteristics")

	# Working data
	working_folder = os.path.join(main_dir, "Working")
	python_working_folder = os.path.join(working_folder, "python_working")
	stata_working_folder = os.path.join(working_folder, "stata_working")

	# Output (cleaned) data
	output_folder = os.path.join(main_dir, "Output")


	print("Wait for the message 'DONE' to show up. The Stata dofile run in the background so it might seem like the program is finished when it isn't")


	run_stata("1_set_presets.do", input_folder=input_folder, output_folder=output_folder)
	run_stata("2_clean_lease.do", input_folder=housing_data_folder, output_folder=stata_working_folder)
	run_stata("3_clean_price.do", input_folder=housing_data_folder, output_folder=stata_working_folder)
	run_stata("4_clean_interest_rates.do", input_folder=interest_rate_data_folder, output_folder=stata_working_folder)
	run_stata("5_merge_on_merge_keys.do", input_folder=stata_working_folder)
	run_python("extract_unmerged_data.py", "postcode", stata_working_folder, python_working_folder)
	run_python("link_unmerged_data.py", "postcode", stata_working_folder, python_working_folder)
	run_stata("6_merge_python_results_postcodes.do", input_folder=stata_working_folder)
	run_python("extract_unmerged_data.py", "city", stata_working_folder, python_working_folder)
	run_python("link_unmerged_data.py", "city", stata_working_folder, python_working_folder)

	# Merge hedonic characteristics with price data
	# append_files(hedonic_data_folder, "certificates.csv", stata_working_folder)
	run_python("extract_unmerged_data.py", "postcode", stata_working_folder, python_working_folder, "-price_file", "full_price_data_unique.dta", "-lease_file","combined_characteristic_files.csv", "-output_lease_file", "headonic_characteristic_properties.p", "-run_lease", "F")
	#run_python("link_unmerged_data.py", "postcode", stata_working_folder, python_working_folder, "-lease_file","headonic_characteristic_properties.p", "-output_file", "matched_hedonic_characteristics.csv", "-v")
	#run_python("link_unmerged_data.py", "postcode", stata_working_folder, python_working_folder, "-lease_file","headonic_characteristic_properties.p", "-output_file", "matched_hedonic_characteristics.csv")


	# run_stata("7_merge_python_results_no_postcodes.do", input_folder=stata_working_folder)
	# run_stata("8_merge_all_data.do", input_folder=stata_working_folder)
	# run_stata("9_finalize_data.do", input_folder=stata_working_folder, output_folder=output_folder)

	# os.chdir(analysis_directory)
	# run_stata("rundirectory.do")
	# run_stata("lease_extensions.do")
	# run_stata("more_lease_variation.do")

	print("DONE")

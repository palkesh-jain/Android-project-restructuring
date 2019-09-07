#!/usr/bin/env bash
rename_files_folder()
{
	if mv "$1" "$2"
	then
        echo "Renamed \"$1\" to \"$2\""
	else
		echo "Issue in renaming \"$1\" to \"$2\""
	fi
}

move_files() 
{
	if mv "$1"* "$2"
	then
		echo "Moved the content of \"$1\" to \"$2\""
	else
		echo "Issue in moving content of \"$1\" to \"$2\""
	fi
}

remove_folder() 
{
	if rm -r "$1"
	then
		echo "Deleted \"$1\""
	else
		echo "Issue in deleting \"$1\""
	fi
}

make_folder() 
{
	if mkdir "$1"
	then
		echo "Created tmp folder at \"$1\""
	else
		echo "Issue in creating tmp folder at \"$1\""
	fi
}

old_package_name=$1
new_package_name=$2
old_app_name=$3
new_app_name=$4

echo "Old Package Name: ${old_package_name}"
echo "New Package Name: ${new_package_name}"

echo "Old App Name: ${old_app_name}"
echo "New App Name: ${new_app_name}"

src_path="/app/src"
app_path="/app"

old_import_name=$(echo "${old_package_name}" | tr / .)
new_import_name=$(echo "${new_package_name}" | tr / .)

echo "Old Import Name: ${old_import_name}"
echo "New Import Name: ${new_import_name}"

#### Change Import Statements ########## 
if find $src_path \( -name "*xml" -o -name "*.java" \) -print0 | xargs -0 sed -ri "s/${old_import_name}/${new_import_name}/g"
then 
        echo "Import Statements has been changed successfully for xml and java files."
else 
        echo "Import Statements changes have some issues when changing for xml and java files. Please check"
fi
        
if find $app_path \( -name "build.gradle" \) -print0 | xargs -0 sed -ri "s/${old_import_name}/${new_import_name}/g"
then
	echo "Import Statements has been changed successfully in build.gradle."
else
	echo "Import Statements changes have some issues in build.gradle. Please check"
fi

#### Change App Name ###################
if find ${src_path}/main/res/values \( -name "strings.xml" \) -print0 | xargs -0 sed -ri "s/${old_app_name}/${new_app_name}/g"
then
	echo "App name has been changed successfully."
else
	echo "App name change have some issues. Please check"
fi

char='/'

old_package_length=$(echo "$old_package_name" | awk -F${char} '{print NF}')
new_package_length=$(echo "$new_package_name" | awk -F${char} '{print NF}')

if [[ $old_package_length < $new_package_length ]]; then
	loop_count=$old_package_length
else 
	loop_count=$new_package_length
fi


for (( i=1; i<=old_package_length; i++ ))
do
   old_package_name_array[i]=$(echo "$old_package_name" | awk -F${char} '{printf("%s", $'"$i"' )}') 
done
for (( i=1; i<=new_package_length; i++ ))
do
   new_package_name_array[i]=$(echo "$new_package_name" | awk -F${char} '{printf("%s", $'"$i"' )}') 
done

#### Change The folder names till no folder creation or deletion required ##########
for (( i = 1; i <= loop_count; i++ )) 
do
	if [[ ${old_package_name_array[i]} != "${new_package_name_array[i]}" ]]; then
		
		rename_files_folder "${src_path}/main/java/${sub_dir}${old_package_name_array[i]}" "${src_path}/main/java/${sub_dir}${new_package_name_array[i]}"
		rename_files_folder "${src_path}/test/java/${sub_dir}${old_package_name_array[i]}" "${src_path}/test/java/${sub_dir}${new_package_name_array[i]}"
		rename_files_folder "${src_path}/androidTest/java/${sub_dir}${old_package_name_array[i]}" "${src_path}/androidTest/java/${sub_dir}${new_package_name_array[i]}"
	fi
	sub_dir+="${new_package_name_array[i]}/"
done

changed_dir_upto=$sub_dir

#### folder deletion is required ##########
if [[ $old_package_length > $new_package_length ]]; then
	for (( i = loop_count+1; i <= old_package_length; i++ )); do
		sub_dir+="${old_package_name_array[i]}/"
	done

	move_files "${src_path}/main/java/${sub_dir}" "${src_path}/main/java/${changed_dir_upto%?}"
	remove_folder "${src_path}/main/java/${changed_dir_upto}${old_package_name_array[$((loop_count+1))]}"

	move_files "${src_path}/test/java/${sub_dir}" "${src_path}/test/java/${changed_dir_upto%?}"
	remove_folder "${src_path}/test/java/${changed_dir_upto}${old_package_name_array[$((loop_count+1))]}"

	move_files "${src_path}/androidTest/java/${sub_dir}" "${src_path}/androidTest/java/${changed_dir_upto%?}"
	remove_folder "${src_path}/androidTest/java/${changed_dir_upto}${old_package_name_array[$((loop_count+1))]}"

elif [[ $old_package_length < $new_package_length ]]; then
	sub_dir=""
	for (( i = 1; i < loop_count; i++ )); do
		sub_dir+="${new_package_name_array[i]}/"
	done

	tmp_folder_main_add="${src_path}/main/java/${sub_dir}tmp"
	tmp_folder_test_add="${src_path}/test/java/${sub_dir}tmp"
	tmp_folder_androidTest_add="${src_path}/androidTest/java/${sub_dir}tmp"
	
	make_folder "${tmp_folder_main_add}"
	make_folder "${tmp_folder_test_add}"
	make_folder "${tmp_folder_androidTest_add}"

	move_files "${src_path}/main/java/${changed_dir_upto}" "${tmp_folder_main_add}/"
	move_files "${src_path}/test/java/${changed_dir_upto}" "${tmp_folder_test_add}/"
	move_files "${src_path}/androidTest/java/${changed_dir_upto}" "${tmp_folder_androidTest_add}/"

	sub_dir=${changed_dir_upto}
	for (( i = loop_count+1; i <= new_package_length; i++ )); do

		make_folder "${src_path}/main/java/${sub_dir}${new_package_name_array[i]}"
		make_folder "${src_path}/test/java/${sub_dir}${new_package_name_array[i]}"
		make_folder "${src_path}/androidTest/java/${sub_dir}${new_package_name_array[i]}"

		sub_dir+="${new_package_name_array[i]}/"
	done

	move_files "${tmp_folder_main_add}/" "${src_path}/main/java/${sub_dir}"
	move_files "${tmp_folder_test_add}/" "${src_path}/test/java/${sub_dir}"
	move_files "${tmp_folder_androidTest_add}/" "${src_path}/androidTest/java/${sub_dir}"

	remove_folder "${tmp_folder_main_add}"
	remove_folder "${tmp_folder_test_add}"
	remove_folder "${tmp_folder_androidTest_add}"

fi

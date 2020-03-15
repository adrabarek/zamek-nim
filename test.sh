mkdir test_zamek
pushd test_zamek
echo "TEST: Create a repository and add notes"
../zamek_cli --verbose create
../zamek_cli --verbose add "Note 0", "tag0, tag1, tag2", "", "Contents of My Note 0."
../zamek_cli --verbose add "Note 1", "tag3, tag1, tag2", "Note 0", "Contents of My NOTE_1."
echo "Contents of Note 2" | ../zamek_cli --verbose add "Note 2", "", ""
../zamek_cli --verbose remove "Note 1"
../zamek_cli --verbose set-content "Note 0" "New content of note 0"
echo
echo "TEST: Create another repository on top of the existing one."
../zamek_cli --verbose create
popd
rm -rf test_zamek
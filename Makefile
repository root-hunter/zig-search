EXEC_PATH=./bin/zig-search
SEARCH_FILE=/mnt/07278d6f-dcd5-4540-ae3f-dc7f08c050e4/Dev/zig-search/results/input
TEST_PARAMS=/mnt/07278d6f-dcd5-4540-ae3f-dc7f08c050e4/Dev/ -S ${SEARCH_FILE} -f bin -t 16 -e /mnt/07278d6f-dcd5-4540-ae3f-dc7f08c050e4/Dev/zig-search/results/zig-result.txt
TEST_PARAMS2=-d "/home/roothunter/" -s "password" -f bin -t 16 -e /mnt/07278d6f-dcd5-4540-ae3f-dc7f08c050e4/Dev/zig-search/results/zig-result.txt
TEST_PARAMS3= -sF /mnt/07278d6f-dcd5-4540-ae3f-dc7f08c050e4/Dev/zig-search/results/input_files.txt -s "password" -f bin -t 16 -e /mnt/07278d6f-dcd5-4540-ae3f-dc7f08c050e4/Dev/zig-search/results/zig-result.txt

build-exe:
	zig build-exe src/main.zig \
	--name zig-search \
	--build-id=sha1 -static

	mv zig-search* bin

# Search all file that cointains the "password" word
test: build-exe
	${EXEC_PATH} ${TEST_PARAMS}

rundev:
	zig run src/main.zig -- ${TEST_PARAMS2}

runrelease:
	./bin/zig-search ${TEST_PARAMS}

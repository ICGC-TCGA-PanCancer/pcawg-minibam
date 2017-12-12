function filterFileArray(str, inArr) {
	var arr = [];
	for (var i = 0; i < inArr.length; i++) {
		if (inArr[i].basename.indexOf(str) >= 0) {
			// Return the first match.
			return inArr[i]
		}
	}
	return arr;
}

function flatten_nested_arrays(array_of_arrays)
{
	var flattened_array = []
	for (var i in array_of_arrays)
	{
		var item = array_of_arrays[i]
		if (item instanceof Array)
		{
			// console.log("found subarray")
			// recursively flatten subarrays.
			var flattened_sub_array = flatten_nested_arrays(item)
			for (var k in flattened_sub_array)
			{
				flattened_array.push(flattened_sub_array[k])
			}
		}
		else
		{
			flattened_array.push(item)
		}
	}
	return flattened_array

}

const dataApiDb = []
const dataApiRead = []
const differences = [];

$(document).ready(function () {
    $('#database-connection-form').on('submit', function (event) {
        event.preventDefault();
        const progressContainer1 = document.getElementById("progress-container");
        const progressBar1 = document.getElementById("progress-bar");

        const progressInterval = progressBar(progressContainer1, progressBar1);

        const formData = $(this).serialize();

        $.ajax({
            url: '/connect_database',
            method: 'POST',
            data: formData,
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function (response) {
                clearInterval(progressInterval);
                progressBar1.style.width = "100%";
                progressBar1.textContent = "100%";
                dataApiDb.push(response);
                console.log(dataApiDb);

                renderTables(response);
            },
        });
    });
    $('#read-file-excel').on('submit', function (event) {
        event.preventDefault();

        const formData = new FormData(this);

        const progressContainer2 = document.getElementById("progress-container2");
        const progressBar2 = document.getElementById("progress-bar2");
        const progressInterval2 = progressBar(progressContainer2, progressBar2);

        $.ajax({
            url: '/read_excel',
            method: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function (response) {
                clearInterval(progressInterval2);
                progressBar2.style.width = "100%";
                progressBar2.textContent = "100%";
                readClicked = true;
                checkButtons();
                dataApiRead.push(response);
                alert("Đọc thành công")


            },
            error: function (xhr, status, error) {
                clearInterval(progressInterval2);
                progressBar2.style.width = "0%";
                progressBar2.textContent = "Đọc file thất bại!";
                alert("Có lỗi xảy ra khi đọc file.");
            }
        });
    });
    $('#btn-compare').on('click', function (event) {
        function compareDbSchemas(apiDb, localDb) {
            const apiTables = apiDb[0].tables;
            const localTables = localDb[0].tables;
            apiTables.sort((a, b) => a.table.localeCompare(b.table));
            localTables.sort((a, b) => a.table.localeCompare(b.table));
            const tablesListContainer = document.getElementById("list-container");
            const differencesContainer = document.getElementById("differences-container");

            apiTables.forEach(apiTable => {
                const localTable = localTables.find(local => local.table === apiTable.table);
                let hasDifferences = false;

                if (!localTable) {
                    const tableElement = tablesListContainer.querySelector(`table[data-table-name="${apiTable.table}"]`);
                    const tableElementName = tablesListContainer.querySelector(`td[data-table-name="${apiTable.table}"]`);
                    if (tableElement) {
                        tableElement.classList.add("table-highlight");
                        tableElementName.classList.add("table-name-highlight");
                        tableElementName.classList.remove("text-gray-700");

                        tableElementName.innerHTML = `
                    <div class="tooltip">
                        ${apiTable.table}
                        <span class="tooltip-text">Bảng này chỉ tồn tại trên cơ sở dữ liệu và không có trong file dữ liệu.</span>
                    </div>
                `;
                        differences.push(`Bảng ${apiTable.table} chỉ tồn tại trên cơ sở dữ liệu.`);
                    }
                    return;
                }

                if (Array.isArray(apiTable.columns)) {
                    apiTable.columns.forEach(apiColumn => {
                        const localColumn = localTable.columns.find(localCol => localCol.name === apiColumn.name);

                        if (!localColumn || apiColumn.data_type !== localColumn.data_type) {
                            hasDifferences = true;
                            const columnElement = tablesListContainer.querySelector(
                                `table[data-table-name="${apiTable.table}"] tbody tr td[data-type-name="${apiColumn.name}_${apiColumn.data_type}"]`
                            );

                            if (columnElement) {
                                columnElement.classList.add("column-highlight");
                                columnElement.innerHTML = `
                            <div class="tooltip">
                                ${apiColumn.data_type}
                                <span class="tooltip-text">Kiểu dữ liệu khác nhau: ${apiColumn.data_type} : ${localColumn ? localColumn.data_type : 'Không có kiểu dữ liệu'}</span>
                            </div>
                        `;
                                differences.push(`Cột ${apiColumn.name} trong bảng ${apiTable.table} có kiểu dữ liệu khác nhau: ${apiColumn.data_type} so với ${localColumn ? localColumn.data_type : 'không xác định'}.`);
                            }
                        }

                        if (!localColumn) {
                            const columnElement = tablesListContainer.querySelector(
                                `table[data-table-name="${apiTable.table}"] tbody tr td[data-column-name="${apiColumn.name}"]`
                            );

                            if (columnElement) {
                                columnElement.classList.add("column-highlight");
                                columnElement.innerHTML = `
                            <div class="tooltip">
                                ${apiColumn.name}
                                <span class="tooltip-text">Không có cột ${apiColumn.name} trong file dữ liệu.</span>
                            </div>
                        `;
                                differences.push(`Không có cột ${apiColumn.name} trong bảng ${apiTable.table}.`);
                            }
                        }
                    });
                }

                if (Array.isArray(localTable.columns)) {
                    localTable.columns.forEach(localColumn => {
                        if (!apiTable.columns.find(apiCol => apiCol.name === localColumn.name)) {
                            hasDifferences = true;
                            differences.push(`Cột ${localColumn.name} trong bảng ${apiTable.table} chỉ tồn tại trong file dữ liệu.`);
                        }
                    });
                }

                if (hasDifferences) {
                    const tableElement = tablesListContainer.querySelector(`table[data-table-name="${apiTable.table}"]`);
                    if (tableElement) {
                        tableElement.classList.add("table-highlight");
                    }
                }
            });

            localTables.forEach(localTable => {
                if (!apiTables.find(apiTable => apiTable.table === localTable.table)) {
                    differences.push(`Bảng ${localTable.table} chỉ tồn tại trong file dữ liệu.`);
                }
            });
        }
        document.getElementById("btn-show").classList.remove("hidden");
        $('#btn-compare').prop('disabled', true);
        $('#btn-compare').addClass('opacity-50 cursor-not-allowed');

        compareDbSchemas(dataApiDb, dataApiRead);
    });
    $('#btn-show').on('click',function (){
        showDifferencesModal(differences)
    })
    let connectionClicked = false;
    let readClicked = false;

    $('#connection').click(function () {
        connectionClicked = true;
        checkButtons();
    });



    function checkButtons() {
        if (connectionClicked && readClicked) {
            $('#btn-compare').prop('disabled', false).removeClass('opacity-50 cursor-not-allowed');
        }
    }
});
function progressBar(progressContainer, progressBar, onComplete) {
    progressContainer.classList.remove("hidden");
    progressBar.style.width = "0%";
    progressBar.textContent = "0%";

    let progress = 0;
    const progressInterval = setInterval(() => {
        if (progress < 90) {
            progress += 10;
            progressBar.style.width = `${progress}%`;
            progressBar.textContent = `${progress}%`;
        } else if (onComplete) {
            onComplete(progressInterval);
        }
    }, 300);

    return progressInterval;
}
function showDifferencesModal(differences) {
    const modal = document.getElementById("differences-modal");
    const differencesContainer = document.getElementById("differences-container");
    differencesContainer.innerHTML = "";

    if (differences.length > 0) {
        differences.forEach((difference) => {
            const differenceItem = document.createElement("div");
            differenceItem.className =
                "p-2 bg-gray-200 border border-gray-300 rounded text-gray-700";
            differenceItem.textContent = difference;
            differencesContainer.appendChild(differenceItem);
        });
    } else {
        differencesContainer.innerHTML =
            '<div class="text-center text-gray-500">Không có khác biệt nào được tìm thấy.</div>';
    }

    modal.classList.remove("hidden");
}
$(document).ready(function () {
    $('#btn-reset').click(function () {
        location.reload();
    });
});

document.getElementById("close-modal").addEventListener("click", () => {
    document.getElementById("differences-modal").classList.add("hidden");

});

document.getElementById("close-modal-btn").addEventListener("click", () => {
    document.getElementById("differences-modal").classList.add("hidden");
});

function renderTables(response) {
    const tables = response.tables;
    const tablesListContainer = document.getElementById("list-container");
    tablesListContainer.innerHTML = '';

    let tableHTML = '';

    tables.forEach(table => {
        tableHTML += `
            <table class=" border  rounded-lg  w-1/3" data-table-name="${table.table}">
                <thead>
                    <tr>
                        <th class="px-6 py-3 text-left text-lg font-semibold text-gray-700 border-b">Tên Bảng</th>
                        <th class="px-6 py-3 text-left text-lg font-semibold text-gray-700 border-b">Cột</th>
                        <th class="px-6 py-3 text-left text-lg font-semibold text-gray-700 border-b">Kiểu Dữ Liệu</th>
                    </tr>
                </thead>
                <tbody>
        `;

        table.columns.forEach((column, index) => {
            tableHTML += `
                <tr class="">
                    ${index === 0 ? `<td class="px-6 py-3 text-gray-700 border-b" rowspan="${table.columns.length}" data-table-name="${table.table}">
                            <div class="tooltip">
                                <strong>${table.table}</strong>
                            </div>
                            </td>` : ''}
                    <td class="px-6 py-3 text-gray-600 border-b" data-column-name="${column.name}">
                    <div class="tooltip">
                            ${column.name}
                        </div>
                        </td>
                    <td class="px-6 py-3 text-gray-600 border-b"   data-type-name="${column.name}_${column.data_type}">
                        <div class="tooltip">
                    ${column.data_type}
                    </div>
                    </td>
                </tr>
            `;
        });

        tableHTML += `
                </tbody>
            </table>
        `;
    });

    tablesListContainer.innerHTML = tableHTML;
}

*** Settings ***
Documentation       Template robot main suite.
...                 Saves the order HTML receipt as a PDF File.
...                 Saves the screenshot of the ordered robot
...                 embeds the screenshot of the robot to the PDF Receipt.
...                 Creates ZIP Archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${url}          https://robotsparebinindustries.com/#/robot-order
${csv_url}      https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot orders web
    Download Excel File
    Fill the form using Excel File
    Create Archive ZIP


*** Keywords ***
Open the robot orders web
    Open Available Browser    ${url}

Close the annoying modal
    Click Button    css:.btn-dark

Download Excel File
    Download    ${csv_url}    overwrite=True

Fill the form using Excel File
    ${orders} =    Read table from csv    orders.csv    header=True
    Close Workbook
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        Create PDF file    ${order}
        Go to order another robot
    END

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Wait Until Page Contains Element    order
    Click Button    preview

Submit The Order
    # Define las variables locales
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]

    #Si falla no genera la captura
    Mute Run On Failure    Page Should Contain Element

    # Si todo esta bien, envia la orden
    Click button    ${btn_order}
    Page Should Contain Element    ${lbl_receipt}

Create PDF file
    [Arguments]    ${order}
    Sleep    5 seconds
    ${reciept_data} =    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${reciept_data}    ${CURDIR}${/}reciepts${/}${order}[Order number].pdf
    Screenshot    //div[@id="robot-preview-image"]    ${CURDIR}${/}robots${/}${order}[Order number].png
    Add Watermark Image To Pdf
    ...    ${CURDIR}${/}robots${/}${order}[Order number].png
    ...    ${CURDIR}${/}reciepts${/}${order}[Order number].pdf
    ...    ${CURDIR}${/}reciepts${/}${order}[Order number].pdf

Go to order another robot
    Wait Until Keyword Succeeds
    ...    3x
    ...    1s
    ...    Wait Until Page Contains Element    order-another
    Click Button    order-another

Create Archive ZIP
    Archive Folder With Zip    ${CURDIR}${/}reciepts    robots_order.zip

*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying model
    Download the csv file
    Get orders and fill the form
    Create ZIP archive
    [Teardown]    Log out and close the browser

*** Keywords ***
Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    
Get orders
    ${orders}=   Read table from CSV    ${CURDIR}${/}orders.csv    header=${True}
    RETURN    ${orders}
Open the robot order website
    Open Available Browser     https://robotsparebinindustries.com/#/robot-order

Close the annoying model
    Click Button When Visible    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Get orders and fill the form
    ${orders}=     Get orders
    FOR       ${row}     IN     @{orders}
        Fill the form     ${row}
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Log    ${pdf}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another
    END
Fill the form
    [Arguments]    ${order}
    Select Radio Button    body    ${order}[Body]
    Select From List By Value    head    ${order}[Head]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Wait Until Keyword Succeeds    5x    1s    Submit the form

Order another
    Click Button    order-another
    Close the annoying model

Submit the form
    Click Button    order
    Assert another order

Assert another order
    Wait Until Page Contains Element    order-another

 Store the receipt as a PDF file
     [Arguments]    ${orderNumber}
     Wait Until Element Is Visible    receipt
     ${receiptPdf}=    Set variable     ${OUTPUT_DIR}${/}receipts${/}${orderNumber}.pdf
     ${receipt}=    Get Element Attribute    receipt    outerHTML
     Html To Pdf    ${receipt}        ${receiptPdf}
     RETURN    ${receiptPdf}

Take a screenshot of the robot
    [Arguments]   ${orderNumber}
     Wait Until Element Is Visible    robot-preview-image
     ${screenshotImage}=     Set Variable    ${OUTPUT_DIR}${/}screenshots${/}${orderNumber}.png
     Screenshot    robot-preview-image    ${screenshotImage}
     RETURN    ${screenshotImage}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${fileList}=    Create List    ${screenshot}
    Add Files To Pdf    ${fileList}    ${pdf}    append=${True}

Create ZIP archive
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}pdfs.zip
    Archive Folder With Tar    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}

Log out and close the browser
    Close Browser
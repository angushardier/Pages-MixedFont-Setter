(*
	Pages Mixed-Script Font Setter
	Version: 1.2.1
	
	自動化中西文混排工具 - 為 Apple Pages 文件套用不同的中英文字型
	
	修正版 1.2.1：
	- 使用批次處理連續的 CJK 字元
	- 直接設定 character range 的 font 屬性
*)

use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

-- Global variables
property chineseFont : ""
property englishFont : ""

-- Main entry point
on run
	try
		-- Step 1: Check if Pages is running and has a document
		if not checkPagesDocument() then
			return
		end if
		
		-- Step 2: Get system fonts and show combined picker dialog
		set fontResult to showFontPickerDialog()
		if fontResult is false then
			return
		end if
		
		-- Step 3: Process the document
		processDocument()
		
		-- Step 4: Show completion notification
		showNotification("處理完成", "中西文混排字型已成功套用。")
		
	on error errMsg number errNum
		display alert "執行錯誤" message "錯誤 " & errNum & ": " & errMsg as critical
	end try
end run

-- Check if Pages has an open document
on checkPagesDocument()
	tell application "System Events"
		if not (exists process "Pages") then
			display alert "未偵測到 Pages" message "請先開啟 Pages 應用程式並打開一個文件。" as critical
			return false
		end if
	end tell
	
	tell application "Pages"
		if (count of documents) = 0 then
			display alert "未偵測到文件" message "請先在 Pages 中開啟一個文件。" as critical
			return false
		end if
	end tell
	
	return true
end checkPagesDocument

-- Get all available font families using NSFontManager (with proper bridging)
on getSystemFontList()
	set fontManager to current application's NSFontManager's sharedFontManager()
	set fontFamiliesNS to fontManager's availableFontFamilies()
	
	-- Sort the font list
	set sortedFonts to fontFamiliesNS's sortedArrayUsingSelector:"localizedCaseInsensitiveCompare:"
	
	return sortedFonts
end getSystemFontList

-- Show combined font picker dialog with two dropdowns using NSAlert
on showFontPickerDialog()
	-- Get font list (as NSArray, keep in Cocoa land)
	set fontList to getSystemFontList()
	set fontCount to fontList's |count|() as integer
	
	-- Create the alert
	set theAlert to current application's NSAlert's alloc()'s init()
	theAlert's setMessageText:"Pages 中西文混排字型設定"
	theAlert's setInformativeText:"請選擇中文與英文字型，然後點擊「套用」開始處理。"
	theAlert's addButtonWithTitle:"套用"
	theAlert's addButtonWithTitle:"取消"
	theAlert's setAlertStyle:(current application's NSAlertStyleInformational)
	
	-- Create a container view for the dropdowns
	set accessoryView to current application's NSView's alloc()'s initWithFrame:(current application's NSMakeRect(0, 0, 350, 100))
	
	-- Chinese font label
	set chineseLabel to current application's NSTextField's labelWithString:"中文字型（漢字、全形標點）："
	chineseLabel's setFrame:(current application's NSMakeRect(0, 70, 200, 20))
	accessoryView's addSubview:chineseLabel
	
	-- Chinese font dropdown
	set chinesePopup to current application's NSPopUpButton's alloc()'s initWithFrame:(current application's NSMakeRect(0, 45, 340, 25)) pullsDown:false
	chinesePopup's addItemsWithTitles:fontList
	-- Try to select default Chinese font
	set defaultChineseIdx to fontList's indexOfObject:"Songti SC"
	if defaultChineseIdx is not equal to (current application's NSNotFound) then
		chinesePopup's selectItemAtIndex:defaultChineseIdx
	end if
	accessoryView's addSubview:chinesePopup
	
	-- English font label
	set englishLabel to current application's NSTextField's labelWithString:"英文字型（拉丁字母、數字）："
	englishLabel's setFrame:(current application's NSMakeRect(0, 22, 200, 20))
	accessoryView's addSubview:englishLabel
	
	-- English font dropdown
	set englishPopup to current application's NSPopUpButton's alloc()'s initWithFrame:(current application's NSMakeRect(0, 0, 340, 25)) pullsDown:false
	englishPopup's addItemsWithTitles:fontList
	-- Try to select default English font
	set defaultEnglishIdx to fontList's indexOfObject:"Times New Roman"
	if defaultEnglishIdx is not equal to (current application's NSNotFound) then
		englishPopup's selectItemAtIndex:defaultEnglishIdx
	end if
	accessoryView's addSubview:englishPopup
	
	-- Set the accessory view
	theAlert's setAccessoryView:accessoryView
	
	-- Bring app to front and show dialog
	current application's NSApp's activateIgnoringOtherApps:true
	set dialogResult to theAlert's runModal()
	
	-- Check result (NSAlertFirstButtonReturn = 1000)
	if dialogResult is not equal to (current application's NSAlertFirstButtonReturn) then
		return false
	end if
	
	-- Get selected fonts
	set chineseFont to (chinesePopup's titleOfSelectedItem()) as text
	set englishFont to (englishPopup's titleOfSelectedItem()) as text
	
	return true
end showFontPickerDialog

-- Check if a character is in CJK range
on isCJKCharacter(theChar)
	set charCode to id of theChar
	
	-- Handle surrogate pairs for characters beyond BMP (> U+FFFF)
	if (class of charCode is list) then
		if (count of charCode) > 1 then
			-- This is a surrogate pair, calculate actual code point
			set highSurrogate to item 1 of charCode
			set lowSurrogate to item 2 of charCode
			set actualCode to ((highSurrogate - 55296) * 1024) + (lowSurrogate - 56320) + 65536
		else
			set actualCode to item 1 of charCode
		end if
	else
		set actualCode to charCode as integer
	end if
	
	-- CJK Unified Ideographs: U+4E00 - U+9FFF (19968 - 40959)
	if actualCode ≥ 19968 and actualCode ≤ 40959 then
		return true
	end if
	
	-- CJK Extension A: U+3400 - U+4DBF (13312 - 19903)
	if actualCode ≥ 13312 and actualCode ≤ 19903 then
		return true
	end if
	
	-- CJK Symbols and Punctuation: U+3000 - U+303F (12288 - 12351)
	if actualCode ≥ 12288 and actualCode ≤ 12351 then
		return true
	end if
	
	-- Fullwidth Forms: U+FF00 - U+FFEF (65280 - 65519)
	if actualCode ≥ 65280 and actualCode ≤ 65519 then
		return true
	end if
	
	-- CJK Extension B and beyond: U+20000 - U+2FA1F (131072 - 195103)
	if actualCode ≥ 131072 and actualCode ≤ 195103 then
		return true
	end if
	
	return false
end isCJKCharacter

-- Build list of contiguous CJK ranges (as {startIdx, endIdx} pairs)
on collectCJKRanges(bodyContent, textLength)
	set ranges to {}
	set inCJKRun to false
	set runStart to 0
	
	repeat with i from 1 to textLength
		set currentChar to character i of bodyContent
		set isCJK to my isCJKCharacter(currentChar)
		
		if isCJK and not inCJKRun then
			-- Start of new CJK run
			set inCJKRun to true
			set runStart to i
		else if not isCJK and inCJKRun then
			-- End of CJK run
			set end of ranges to {runStart, i - 1}
			set inCJKRun to false
		end if
	end repeat
	
	-- Handle case where document ends with CJK
	if inCJKRun then
		set end of ranges to {runStart, textLength}
	end if
	
	return ranges
end collectCJKRanges

-- Process the Pages document
on processDocument()
	tell application "Pages"
		activate
		
		tell front document
			-- Get the body text as string
			set bodyContent to body text as text
			set textLength to count of characters of bodyContent
			
			if textLength = 0 then
				return
			end if
			
			-- Show progress notification
			my showNotification("處理中...", "正在分析 " & textLength & " 個字元...")
			
			-- Step 1: Apply English font to entire body text
			set font of body text to my englishFont
			
			-- Step 2: Collect CJK ranges
			set cjkRanges to my collectCJKRanges(bodyContent, textLength)
			set rangeCount to count of cjkRanges
			
			if rangeCount = 0 then
				-- No CJK characters found
				return
			end if
			
			-- Show progress notification
			my showNotification("套用中文字型...", "正在處理 " & rangeCount & " 個中文區段...")
			
			-- Step 3: Apply Chinese font to each CJK range
			repeat with rangeItem in cjkRanges
				set startIdx to item 1 of rangeItem
				set endIdx to item 2 of rangeItem
				
				-- Apply font to character range
				set font of characters startIdx thru endIdx of body text to my chineseFont
			end repeat
		end tell
	end tell
end processDocument

-- Show a macOS notification
on showNotification(notifTitle, notifMessage)
	display notification notifMessage with title "Pages 混排工具" subtitle notifTitle
end showNotification

# this file generated when environment is closed
# refresh . to make sure sizes are right

wm deiconify .
update
wm withdraw .
if {[winfo screenwidth .] != 1382 || [winfo screenheight .] != 864 || [lindex [wm maxsize .] 0] != 8580 || [lindex [wm maxsize .] 1] != 1421} {
  set size_mismatch 1
} else {
  set size_mismatch 0
}

if $size_mismatch {
  set reset_window_sizes [tk_messageBox -icon warning -title "Screen resolution changed" -type yesno \
                                         -message "The screen resolution is not the same as it was the last time the Environment was used.  Should the window positions reset to the defaults?"]
} else { set reset_window_sizes 0}
if {$reset_window_sizes != "yes"} {
  set window_config(.whynotdm) 257x277+591+282
  set changed_window_list(.whynotdm) 1
  set window_config(.visicon) 834x342+5152+1008
  set changed_window_list(.visicon) 1
  set window_config(.text_trace_history) 714x340+304+262
  set changed_window_list(.text_trace_history) 1
  set window_config(.graphic_trace) 1382x793+-23+-17
  set changed_window_list(.graphic_trace) 1
  set window_config(.buffers) 470x240+4704+100
  set changed_window_list(.buffers) 1
  set window_config(.control_panel) 235x700+5729+39
  set changed_window_list(.control_panel) 1
  set window_config(.param_viewer) 400x330+4749+408
  set changed_window_list(.param_viewer) 1
  set window_config(.audicon) 867x150+5129+807
  set changed_window_list(.audicon) 1
  set window_config(.stepper) 500x550+5192+62
  set changed_window_list(.stepper) 1
  set window_config(.pick_buffers) 200x340+792+310
  set changed_window_list(.pick_buffers) 1
  set window_config(.declarative) 420x431+4719+891
  set changed_window_list(.declarative) 1
  set window_config(.whynot) 568x411+591+282
  set changed_window_list(.whynot) 1
  set window_config(.procedural) 1234x522+3470+519
  set changed_window_list(.procedural) 1
  set window_config(.copyright) 400x290+491+287
  set changed_window_list(.copyright) 1
}
set gui_options(p_selected) #44DA22
set gui_options(p_matched) #FCA31D
set gui_options(p_mismatched) #E1031E

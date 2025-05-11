##__BEGIN_OF_FORMDESIGNER__
## CAUTION!! ## This code was automagically ;-) created by FormDesigner.
## NEVER modify manualy -- otherwise, you'll have a terrible experience.

require 'vr/vruby'
require 'vr/vrcontrol'

class Form1 < VRForm

  def construct
    self.caption = 'JBSL Checker'
    self.move(575,182,591,339)
    addControl(VRButton,'button_log',"LOG OPEN",408,24,112,32)
    addControl(VRButton,'button_manual',"MANUAL CHECK",400,72,152,32)
    addControl(VRCombobox,'comboBox_league',"",32,32,352,300)
    addControl(VRStatic,'static1',"League",32,8,96,24)
    addControl(VRStatic,'static_time',"",176,8,200,24)
  end 

end

##__END_OF_FORMDESIGNER__

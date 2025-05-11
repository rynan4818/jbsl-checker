#! ruby -Ks
# -*- mode:ruby; coding:shift_jis -*-
$KCODE='s'

#Set 'EXE_DIR' directly at runtime  ���ڎ��s����EXE_DIR��ݒ肷��
EXE_DIR = (File.dirname(File.expand_path($0)).sub(/\/$/,'') + '/').gsub(/\//,'\\') unless defined?(EXE_DIR)

#Available Libraries  �g�p�\���C�u����
#require 'jcode'
require 'nkf'
#require 'csv'
#require 'fileutils'
#require 'pp'
#require 'date'
require 'time'
#require 'base64'
require 'win32ole'
#require 'Win32API'
#require 'vr/vruby'
require 'vr/vrcontrol'
require 'vr/vrtimer'
#require 'vr/vrcomctl'
#require 'vr/clipboard'
#require 'vr/vrddrop.rb'
require 'json'

#Predefined Constants  �ݒ�ςݒ萔
#EXE_DIR ****** Folder with EXE files[It ends with '\']  EXE�t�@�C���̂���f�B���N�g��[������\]
#MAIN_RB ****** Main ruby script file name  ���C����ruby�X�N���v�g�t�@�C����
#ERR_LOG ****** Error log file name  �G���[���O�t�@�C����

require 'vr/vruby'
require '_frm_jbsl-checker'

CURL_TIMEOUT = 10
RELOAD_TIME = 10 * 60
$winshell  = WIN32OLE.new("WScript.Shell")
LOG_FILE = "jbsl-checker-log.txt"

#SJIS �� UTF-8�ϊ�#
def utf8cv(str)
  if str.kind_of?(String)                       #�����ɓn���ꂽ���e��������̏ꍇ�̂ݕϊ�����������
    return NKF.nkf('-w --ic=CP932 -m0 -x',str)  #NKF���g����SJIS��UTF-8�ɕϊ����ĕԂ�
  else
    return str                                  #������ȊO�̏ꍇ�͂��̂܂ܕԂ�
  end
end

#UTF-8 �� SJIS�ϊ�#
def sjiscv(str)
  if str.kind_of?(String)                       #�����ɓn���ꂽ���e��������̏ꍇ�̂ݕϊ�����������
    return NKF.nkf('-W --oc=CP932 -m0 -x',str)  #NKF���g����UTF-8��SJIS�ɕϊ����ĕԂ�
  else
    return str                                  #������ȊO�̏ꍇ�͂��̂܂ܕԂ�
  end
end

def jbsl_check(last, now)
  mes = total_rank_check(last, now)
  mes += maps_rank_check(last, now)
  mes = "��#{sjiscv(now['league_title'])}��\n#{mes}" if mes != ''
  return mes
end

def total_rank_check(last, now)
  mes = ''
  last['total_rank'].each do |last_r|
    now['total_rank'].each do |now_r|
      if last_r['sid'] == now_r['sid']
        t = ''
        t += " ���ʕϓ�:#{last_r['standing']}��#{now_r['standing']}" if last_r['standing'] != now_r['standing']
        t += " P�ϓ�:#{last_r['pos']}��#{now_r['pos']}" if last_r['pos'] != now_r['pos']
        mes += "#{sjiscv(now_r['name'])}:#{t}\n" if t != ''
        break
      end
    end
  end
  mes = "���������ʕϓ�\n#{mes}" if mes != ''
  return mes
end

def maps_rank_check(last, now)
  mes = ''
  last['maps'].each do |last_m|
    now['maps'].each do |now_m|
      if last_m['hash'] == now_m['hash']
        m = ''
        last_m['scores'].each do |last_s|
          now_m['scores'].each do |now_s|
            if last_s['sid'] == now_s['sid']
              t = ''
              t += " ���ʕϓ�:#{last_s['standing']}��#{now_s['standing']}" if last_s['standing'] != now_s['standing']
              t += " ACC�ϓ�:%.2f��%.2f" % [last_s['acc'],now_s['acc']] if last_s['acc'] != now_s['acc']
              m += "#{sjiscv(now_s['name'])}:#{t}\n" if t != ''
              break
            end
          end
        end
        mes += "��#{sjiscv(now_m['title'])}\n#{m}" if m != ''
      end
    end
  end
  mes = "�����ʕϓ�\n#{mes}" if mes != ''
  return mes
end

def league_check(league_id)
  lastcheck_file = "#{league_id}_check.json"
  jbsl_api_url = "https://jbsl-web.herokuapp.com/leaderboard/api/#{league_id}"
  begin
    jbsl_json = `curl -k -Ss --connect-timeout #{CURL_TIMEOUT} #{jbsl_api_url}`
    $KCODE = "UTF8"
    jbsl_data = JSON.parse(jbsl_json)
    $KCODE='s'
  rescue
    puts "LEAGUE JSON GET ERR"
    exit
  end

  if File.exist?(lastcheck_file)
    begin
      $KCODE = "UTF8"
      last_data = JSON.parse(File.read(lastcheck_file))
      $KCODE='s'
    rescue
      puts "LAST DATA ERR"
      exit
    end
    mes = jbsl_check(last_data, jbsl_data)
  end

  File.open(lastcheck_file, 'w') do |f|
    f.print jbsl_json
  end
  return mes
end

def active_league_set
  active_league = "https://jbsl-web.herokuapp.com/api/active_league"
  begin
    json = `curl -k -Ss --connect-timeout #{CURL_TIMEOUT} #{active_league}`
    $KCODE = "UTF8"
    active_league_data = JSON.parse(json)
    $KCODE='s'
  rescue
    puts "ACTIVE LEAGUE JSON GET ERR"
    exit
  end
  names = []
  ids = []
  active_league_data.each do |league|
    names.push sjiscv(league["name"])
    ids.push league["id"]
  end
  return [names, ids]
end

def log_append(mes)
  File.open(LOG_FILE, 'a') do |f|
    f.print mes
  end
end

class Form1                                                         ##__BY_FDVR
  include VRTimerFeasible

  def self_created
    @reload_time = Time.now + RELOAD_TIME
    addTimer 1000,"t1"
    @leagues_name, @leagues_id = active_league_set
    @leagues_name.unshift "ALL LEAGUE"
    @leagues_id.unshift -1
    @comboBox_league.setListStrings(@leagues_name)
    @comboBox_league.select(0)
    @now_league_id = -1
    main_check(@now_league_id)
  end
  
  def button_log_clicked
    $winshell.Run("\"#{EXE_DIR + LOG_FILE}\"") if File.exist?(EXE_DIR + LOG_FILE)
  end

  def button_manual_clicked
      @reload_time = Time.now + RELOAD_TIME
      main_check(@now_league_id)
  end

  def comboBox_league_selchanged
    @now_league_id = @leagues_id[@comboBox_league.selectedString]
  end

  def t1_timer
    if @reload_time < Time.now
      @reload_time = Time.now + RELOAD_TIME
      main_check(@now_league_id)
    end
    @static_time.caption = "AUTO RELOAD TIME #{(@reload_time - Time.now).to_i}sec"
  end
  
  def main_check(league_id)
    print "�`�F�b�N��"
    flag = false
    if league_id == -1
      @leagues_id.each do |id|
        next if id == -1
        mes = league_check(id)
        if mes == ''
          print '.'
        else
          flag = true
          puts
          log_append(mes)
          puts mes
        end
      end
    else
      mes = league_check(league_id)
        if mes == ''
          puts '.'
        else
          flag = true
          puts
          log_append(mes)
          puts mes
        end
    end
    $winshell.Run("rundll32 user32.dll,MessageBeep") if flag
    puts "����"
  end
end                                                                 ##__BY_FDVR

VRLocalScreen.start Form1

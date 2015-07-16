#!/usr/bin/env python

# VoipNow debug script
# (c) 4PSA, 2015

# imports
import re,sys,datetime,socket,subprocess,sys,os,signal,tarfile,re
import gzip,hashlib,glob,fnmatch,time,bz2,random,string,pwd,grp

# global variables 
log_path = '/usr/local/voipnow/admin/htdocs/'
FNULL = open(os.devnull, 'w')


# helper functions
class colors:
  HEADER = '\033[95m'
  OKBLUE = '\033[94m'
  OKGREEN = '\033[92m'
  WARNING = '\033[93m'
  FAIL = '\033[91m'
  ENDC = '\033[0m'
  BOLD = '\033[1m'
  UNDERLINE = '\033[4m'
  WOB = '\033[1;37;40m'
  OOB = '\033[1;31;40m'

def header():
  print "\n" + colors.WOB + " 4" + colors.ENDC + colors.OOB + "PSA" + colors.ENDC + colors.BOLD + " VoipNow 3-in-1 debug script" + colors.ENDC + "\n"

def ansi_log(t):
  print colors.BOLD + "[*] " + colors.ENDC + t

def usage():
  header()
  print "This script will collect extended debug data from your VoipNow system.\n"
  print "Arguments:"
  print " <ticket id> - mandatory argument; a numeric ticket ID as given by 4PSA support"
  print " [dump type] - optional, can be one of " + colors.BOLD + "sigonly" + colors.ENDC + " or " + colors.BOLD + "full" + colors.ENDC + " (defaults to sigonly)"
  print " [SIP log level] - optional, can be 2 or 3 (defaults to 2)"
  print "\nExamples:\n" 
  print " " + colors.BOLD + "python 4psadebug.py 20030" + colors.ENDC
  print " " + colors.BOLD + "python 4psadebug.py 12345 full 3" + colors.ENDC  
  print "\n"
  sys.exit(1)
  
def is_number(s):
  try:
    int(s)
    return True
  except ValueError:
    return False

# enable debug in console logging for Asterisk
def log_enabler():
  searched = '^console( )*=>( )*notice'
  outfile = open('/etc/asterisk/logger.conf.tmp', 'w')
  with open('/etc/asterisk/logger.conf') as infile:
    for line in infile:
      if re.match(searched, line):
        outfile.write('console => debug,fax,notice,warning,error\n')
      else:
        outfile.write(line)
  uid = pwd.getpwnam("asterisk").pw_uid
  gid = grp.getgrnam("asterisk").gr_gid
  os.chown('/etc/asterisk/logger.conf.tmp', uid, gid)
  os.remove('/etc/asterisk/logger.conf')
  os.rename('/etc/asterisk/logger.conf.tmp','/etc/asterisk/logger.conf')
  
          
    
# preflight checks
try:
  ticket_id = str(sys.argv[1])
  if len(sys.argv) > 2:
    how_tcp = str(sys.argv[2])
  if len(sys.argv) > 3:
    how_kama = str(sys.argv[3])
except IndexError:
  usage()

# argument checks
if len(sys.argv)<2 or len(sys.argv)>4:
  usage()
if not is_number(ticket_id):
  usage()
if ('how_tcp' in locals()) and (how_tcp != 'full' and how_tcp != 'sigonly'):
  print "in tcp"
if ('how_kama' in locals()) and (how_kama != '2' and how_kama != '3'):
  usage()

# helper classes 

# tcpdump helper
class PKT(object):
  def __init__(self):
    print "Packet capture initialized."
  def __del__(self):
    print "Packet captured terminated."
  def start(self):
    print "Starting packet capture - press CTRL+C after your call is finished."
    cmd_tcpdump = ['tcpdump', '-nni','any','-s','0', 'udp port 5050 or port 5060','-v','-w',log_path + ticket_id + '.pcap']
    self.process = subprocess.Popen(cmd_tcpdump,stdout=FNULL,stderr=FNULL,shell=False,preexec_fn=os.setsid)
    self.process.wait()
  def stop(self):
    print "Stopping packet capture ..."
    os.killpg(self.process.pid,signal.SIGTERM)

        
# asterisk helper
class PBX(object):
  def __init__(self):
    print "PBX logging initialized."
  def __del__(self):
    print "PBX logging terminated."
  def start(self):
    print "Starting PBX debug logging"
    cmd_verbose = ['asterisk', '-rx', 'core set verbose 111111']
    cmd_core = ['asterisk', '-rx', 'core set debug 111111']
    cmd_sip = ['asterisk', '-rx', 'sip set debug on']
    subprocess.call(cmd_verbose,shell=False,stdout=FNULL,stderr=FNULL)
    subprocess.call(cmd_core,shell=False,stdout=FNULL,stderr=FNULL)
    subprocess.call(cmd_sip,shell=False,stdout=FNULL,stderr=FNULL)
    self.pbx_log = open(log_path + ticket_id + '.pbx', 'w')
    cmd_asttail = ['tail','-f','/var/log/asterisk/messages']
    self.process = subprocess.Popen(cmd_asttail,stdout=self.pbx_log,stderr=FNULL,shell=False,preexec_fn=os.setsid)
  def stop(self):
    print "Stopping PBX debug logging"
    cmd_verbose = ['asterisk', '-rx', 'core set verbose 0']
    cmd_core = ['asterisk', '-rx', 'core set debug 0']
    cmd_sip = ['asterisk', '-rx', 'sip set debug off']
    subprocess.call(cmd_verbose,shell=False,stdout=FNULL,stderr=FNULL)
    subprocess.call(cmd_core,shell=False,stdout=FNULL,stderr=FNULL)
    subprocess.call(cmd_sip,shell=False,stdout=FNULL,stderr=FNULL)
    self.pbx_log.close()
    os.killpg(self.process.pid,signal.SIGTERM)
  def logger_reload(self):  
    cmd_logger_reload = ['asterisk', '-rx', 'logger reload']
    subprocess.call(cmd_logger_reload,shell=False,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
  
# kamailio helper
class SIP(object):
  def __init__(self):
    print "SIP logging initialized."
  def __del__(self):
    print "SIP logging terminated."
  def start(self):
    print "Starting SIP debug logging"
    cmd_kamctl = ['kamctl','fifo','debug','3']
    subprocess.call(cmd_kamctl,shell=False,stdout=FNULL,stderr=FNULL)
    cmd_kamtail = ['tail','-f','/var/log/kamailio.log']
    self.sip_log = open(log_path + ticket_id + '.sip','w')
    self.process = subprocess.Popen(cmd_kamtail,stdout=self.sip_log,shell=False,preexec_fn=os.setsid,stderr=FNULL)    
  def stop(self):
    print "Stopping SIP debug logging"
    cmd_kamctl = ['kamctl','fifo','debug','-1']
    subprocess.call(cmd_kamctl,shell=False,stdout=FNULL,stderr=FNULL)
    self.sip_log.close()
    os.killpg(self.process.pid,signal.SIGTERM)

# void main()
header()

try:     
  iPKT = PKT()
  iPBX = PBX()
  iSIP = SIP()
  log_enabler()
  iPBX.logger_reload()
  iPBX.start()
  iSIP.start()
  iPKT.start()
except KeyboardInterrupt:
  ansi_log("CTRL+C received, stopping...")
  iPKT.stop()
  iPBX.stop()
  iSIP.stop()
  ansi_log("Creating log archive...")
  log_archive = tarfile.open(log_path + ticket_id + ".tar.gz", "w:gz")
  log_archive.add(log_path + ticket_id + '.pcap', arcname = ticket_id + '.pcap')
  log_archive.add(log_path + ticket_id + '.sip', arcname = ticket_id + '.sip')
  log_archive.add(log_path + ticket_id + '.pbx', arcname = ticket_id + '.pbx')
  log_archive.close()
  uid = pwd.getpwnam("voipnow").pw_uid
  gid = grp.getgrnam("voipnow").gr_gid
  path = log_path + ticket_id + ".tar.gz"
  os.chown(path, uid, gid)
  os.remove(log_path + ticket_id + '.pcap')
  os.remove(log_path + ticket_id + '.sip')
  os.remove(log_path + ticket_id + '.pbx')
  x = [(s.connect(('8.8.8.8', 80)), s.getsockname()[0], s.close()) for s in [socket.socket(socket.AF_INET, socket.SOCK_DGRAM)]][0][1]
  ansi_log("Your capture is at https://" + x + "/" + ticket_id + ".tar.gz")
  FNULL.close()  
  

#!/usr/bin/perl
# author : chen zhuo wen
# function : compress and upload to ftp.
#dpi数据上传脚本
use strict;
use Sys::Syslog;
use Net::FTP;

my $to_do_file = $ARGV[0]; 
my $output_path = "/home/dpi_filter";
my $tar_path = "/home/dpi_tar";

syslog('info', "Start FTP.");
#FTP使用binary格式上传
my $ftp = Net::FTP->new("10.230.245.220") or syslog('warning', "Cannot connet FTP.");
$ftp->login("dpiuser", "gzsendi") or syslog('warning', "Cannot login FTP");
$ftp->binary;
$ftp->cwd("upload");
#压缩 /home/dpi_filter/home_dpi_LTEUP_TOPICVIDEO_20160405_201604052309_201604052334
my $tar_file = "$tar_path/$to_do_file".".gz";
`tar czvf $tar_file $output_path/$to_do_file > /dev/null 2>&1 && rm -f $output_path/$to_do_file` and syslog('warning', "Cannot compress $to_do_file.");
#上传
$ftp->put("$tar_file") and `rm -f $tar_file` or syslog('warning', "Cannot upload $tar_file and delete local file.");
$ftp->quit and syslog('info', "ftp disconnet.");




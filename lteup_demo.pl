#!/usr/bin/perl
#author : chen zhuo wen
#function : demo script 
#模版脚本

use strict;
use Sys::Syslog;
use POSIX qw(strftime);
#use Net::FTP;

my $data_path = "replace_data_path"; 
#my $today = strftime("%Y%m%d", localtime);
#my $data_path = "/home/dpi/LTEUP_VIDEO/$today";

my $output_path = "/home/dpi_filter";
my $log_file = "/var/log/dpi_filter.log";

syslog('info', "Start");

unless( -d $data_path )
{
    syslog('warning', "$data_path is not exists.");
    exit;
}

my @data_list;
@data_list = glob "$data_path/*";
@data_list = sort @data_list;
#剔除最后一个文件,以防为最新的.
splice(@data_list,-1);

#是否有文件需要处理
unless ( @data_list ){
    syslog('info', "no more than two data files and exiting...");
    exit 0;
}

my $count = 0;
my $total = 1;
my $total_file;
my $fail_data_count;

syslog('info', "Start to filter file of $data_path.");

my $start_tag;
my $end_tag;
foreach my $data_file_do (@data_list)
{
        if ( $count < 20 )
        {
            $count = $count+1;      
            #$total_file="LTEUP_VIDEO_totalfile_"."$total";
            #my $time = strftime("%Y%m%d%H%M%S", localtime);
            $total_file = "replace_content"."_total_"."$total"; #replace_content: home_dpi_LTEUP_GAME_20160404
            if ( $count == 1 ){ 
                syslog('info' ,"Start to combine $total_file.");
                #ETL_LTEUP_Video_201604042340.40.1192.csv.done
                if ( $data_file_do =~ /(\d{12})/ ){
                    $start_tag = $1 ;
                }
            }
            #过滤数据情况
            open(W, ">>$output_path/$total_file") or syslog('warning', "Cannot open $total_file to write.");
            open(R, "$data_file_do") or syslog('warning', "Cannot open $data_file_do."); 
                while( my $line = <R> )
                {
                        my @tmp = split(/\001/, $line);
                        #if ( $tmp[0] && $tmp[6] && $tmp[47] && $tmp[48] && $tmp[49] && $tmp[50] && $tmp[58] && $tmp[76] )
                        if ( replace_filter_field )
                        { 
                            print W "$line";
                        }
                        else    
                        {
                            $fail_data_count = $fail_data_count + 1;
                        }
                }
            close(R);
            close(W);
            `rm -f $data_file_do`;
            
            if ( $count == 20 or $data_file_do eq $data_list[-1] ) 
            {
                syslog('info' ,"finish combine $total_file.");
                if ( $data_file_do =~ /(\d{12})/ ){
                    $end_tag = $1 ; 
                }
                #重命名
                my $rename = "replace_content"."_${start_tag}"."_${end_tag}";
                `mv $output_path/$total_file $output_path/$rename` and syslog('warning', "Cannot rename $total_file.") or syslog('info', "rename $total_file to $rename.");
                #压缩上传
                system("/usr/bin/perl /home/sdnmuser/sendi_lteup_uploadfile.pl $rename &") and syslog('warning', "Cannot compress and upload $rename.");
            }

        }
        else
        {
            $count = 0;
            $total = $total+1;
            redo;
        }
}
#记录剔除数据数量
my $logtime = strftime("%Y%m%d%H%M%S", localtime);
open(WLOG, ">>$log_file");
print WLOG "[$logtime]:[$data_path] the number of error line : $fail_data_count\n";
close(WLOG);

syslog('info', "finishing filter.");



#!/usr/bin/perl
#author : 815490748@qq.com
#function : create dynamic script and fork process to filter 
#合并过滤数据入口perl脚本

use strict;
use POSIX qw(strftime);
use Sys::Syslog;

syslog('info', "Start.")

#监控目录
my $data_path = "/home/dpi";
my @to_do_path = `du -Sh $data_path/LTEUP*`;
my @do_directory;
chomp(@to_do_path);
foreach my $match (@to_do_path)
{
	#有文件
	if ( $match !~ /4.0K/ ){
		my @tmp = split(/\t/,$match);
		push(@do_directory, $tmp[1]);
	}
}

my %pid_to_host;  
#控制进程数量      
sub wait_for_a_kid {
        my $pid = wait;                                                                                          
        return 0 if $pid < 0;                                                                                     
        my $host = delete $pid_to_host{$pid} or warn("Why did I see $pid ($?)\n"), next;#删除哈希数组元素
        1;
}

#识别数据类型并处理
foreach my $do_dir (@do_directory)
{
	&wait_for_a_kid if(keys %pid_to_host >=5); 
	if ( $do_dir =~ /LTEUP_VIDEO/ ){
		my $filter_field = '$tmp[0] && $tmp[6] && $tmp[47] && $tmp[48] && $tmp[49] && $tmp[50] && $tmp[58] && $tmp[76]';
		&fliter_data($do_dir, $filter_field);
	}
	if ( $do_dir =~ /LTEUP_QQIM/ ){
		my $filter_field = '$tmp[0] && $tmp[10] && $tmp[21]';
		&fliter_data($do_dir, $filter_field);
	}
	if ( $do_dir =~ /LTEUP_WEIXIN/ ){
		my $filter_field = '$tmp[0] && $tmp[10] && $tmp[21]';
		&fliter_data($do_dir, $filter_field);
	}
	if ( $do_dir =~ /LTEUP_GAME/ ){
		my $filter_field = '$tmp[0] && $tmp[6] && $tmp[49] && $tmp[50] && $tmp[59] && $tmp[63] && $tmp[76]';
		&fliter_data($do_dir, $filter_field);		
	}
	if ( $do_dir =~ /LTEUP_TOPICVIDEO/ ){
		my $filter_field = '$tmp[0] && $tmp[6] && $tmp[10] && $tmp[28] && $tmp[29] && $tmp[40]';
		&fliter_data($do_dir, $filter_field);	
	}
	if ( $do_dir =~ /LTEUP_HTTPWAP/ ){
		my $filter_field = '$tmp[0] && $tmp[6] && $tmp[49] && $tmp[50]  && $tmp[59] && $tmp[63] && $tmp[76]';
		&fliter_data($do_dir, $filter_field);		
	}
}

#动态代码并执行
sub fliter_data {
	my $pid = fork ;
	if ( $pid == 0 ) 
	{
		my ($target_dir, $filter_field) = @_ ;
		#读脚本模块
	    my $script_path = "/home/sdnmuser/sendi_lteup_demo.pl";
	    open(F, "$script_path") or syslog('warning', "Cannot open $script_path.");
	    my $script_code ;
		$script_code .= $_ while(<F>);
	    close(F);	
	    my $content = $target_dir;
	    $content =~ s/\//_/g;
		$content =~ s/^_//; # home_dpi_LTEUP_GAME_20160404
	    #生成动态代码
	    $script_code =~ s/replace_data_path/$target_dir/;
	    $script_code =~ s/replace_filter_field/$filter_field/;
	    $script_code =~ s/replace_content/$content/g; 
	    my $time = strftime("%Y%m%d%H%M%S", localtime);
	    my $dynamic_script = "/home/sdnmuser/dynamic/"."$content"."_$time".".pl";
	    open(W,">$dynamic_script") or syslog('warning', "Couldn't write $dynamic_script.");
	    print W $script_code;
	    close(W);

	    system("/usr/bin/perl $dynamic_script") and syslog('warning', "Couldn't execute $dynamic_script."); #shell执行成功返回0

	    exit 0;
 	}
 	elsif ( $pid > 0 )
 	{
 		$pid_to_host{$pid} = 1;
 		syslog('info', "create $pid.");
 	}
 	else
 	{
 		syslog('warning', "Couldn't fork($pid) :$!\n");
 	}
}


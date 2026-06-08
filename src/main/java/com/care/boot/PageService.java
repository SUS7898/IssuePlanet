package com.care.boot;

public class PageService {
	public static String printPage(String url, int totalCount, int pageBlock, int currentPage) {
		
		String result = "";
		
		if(currentPage > 1)
			result += "<a href='" + url + (currentPage-1)+ "'> 이전 </a>";
		else
			result += "<a href='" + url +"1'> 이전 </a>";
		
		int totalPage = totalCount / pageBlock;
		if(totalCount % pageBlock != 0)
			totalPage++;
		
		for(int i = 1; i <= totalPage; i++ ) {
			if(currentPage == i)
				result += "<a href='" + url + i+ "'> <b>[" + i +"]</b> </a>";
			else
				result += "<a href='" + url + i+ "'> [" + i +"] </a>";
		}
		
		if(currentPage < totalPage)
			result += "<a href='" + url + (currentPage+1)+ "'> 다음 </a>";
		else
			result += "<a href='" + url + totalPage+"'> 다음 </a>";
		
		return result;
	}
}







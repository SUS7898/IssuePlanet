package com.care.boot.board;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface BoardMapper {

	List<BoardDTO> boardForm (@Param("begin")int begin, @Param("end")int end);

	int totalCount();

	void boardWriteProc(BoardDTO board);

	BoardDTO boardContent(int n);

	void incrementHits(int n);

	String boardDownload(int n);

	int boardModifyProc(BoardDTO board);

	void boardDeleteProc(int n);

}





